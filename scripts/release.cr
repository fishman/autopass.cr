require "json"
require "gpg"
require "http/client"
require "file_utils"
require "dotenv"

Dotenv.load

class Releaser
  PROJECT_NAME = "repomaa/autopass.cr"

  struct Upload
    include JSON::Serializable

    getter alt : String
    getter url : String
    getter markdown : String
  end

  struct Release
    include JSON::Serializable

    getter tag_name : String
    getter description : String
    getter name : String
    getter assets : Assets
  end

  struct Assets
    include JSON::Serializable

    getter sources : Array(Source)
  end

  struct Source
    include JSON::Serializable

    getter format : String
    getter url : String
  end

  private getter client, gpg
  @tag : String?
  @description : String?

  def initialize
    @client = HTTP::Client.new("gitlab.com", tls: true)
    @client.before_request do |request|
      puts "#{request.method} #{request.path}"
      request.headers["PRIVATE-TOKEN"] = ENV["GITLAB_TOKEN"]
    end

    @gpg = GPG.new
  end

  def create_release
    data = HTTP::Params.build do |params|
      params.add("tag_name", tag)
      params.add("description", description)
    end

    client.post(
      "#{project_path}/releases",
      body: data,
      headers: HTTP::Headers{"Content-Type" => "application/x-www-form-urlencoded"}
    ) do |response|
      raise response.body_io.gets_to_end unless response.success?
    ensure
      response.body_io.skip_to_end
    end

    upload_binary_and_signatures
  end

  def upload_binary_and_signatures
    binary do |path|
      upload = upload_file(path, "application/octet-stream")
      add_link(File.basename(path), "https://gitlab.com/#{PROJECT_NAME}/#{upload.url}")
      upload_signature(path)
    end

    tar do |path|
      upload = upload_file(path, "application/octet-stream")
      add_link(File.basename(path), "https://gitlab.com/#{PROJECT_NAME}/#{upload.url}")
      upload_signature(path)
    end

    tar_gz do |path|
      upload = upload_file(path, "application/octet-stream")
      add_link(File.basename(path), "https://gitlab.com/#{PROJECT_NAME}/#{upload.url}")
      upload_signature(path)
    end

    tar_bz2 do |path|
      upload = upload_file(path, "application/octet-stream")
      add_link(File.basename(path), "https://gitlab.com/#{PROJECT_NAME}/#{upload.url}")
      upload_signature(path)
    end

    zip do |path|
      upload = upload_file(path, "application/octet-stream")
      add_link(File.basename(path), "https://gitlab.com/#{PROJECT_NAME}/#{upload.url}")
      upload_signature(path)
    end
  end

  private def upload_signature(path)
    File.open(path) do |file|
      sig_path = "#{path}.sig"
      File.open(sig_path, "w+") do |sig_file|
        sig_file.print(gpg.sign(file.gets_to_end, GPG::SigMode::Detach))
      end

      upload = upload_file(sig_path, "application/octet-stream")
      add_link(File.basename(sig_path), "https://gitlab.com/#{PROJECT_NAME}/#{upload.url}")
    end
  end

  private def add_link(name, url)
    data = HTTP::Params.build do |params|
      params.add("name", name)
      params.add("url", url)
    end

    pp data
    client.post(
      "#{project_path}/releases/#{tag}/assets/links",
      body: data,
      headers: HTTP::Headers{"Content-Type" => "application/x-www-form-urlencoded"}
    ) do |response|
      raise response.body_io.gets_to_end unless response.success?
    ensure
      response.body_io.skip_to_end
    end
  end

  private def binary
    clean_project do |project|
      bin_file = "#{project}/bin/autopass"
      FileUtils.cd(project) do
        Process.run("shards", ["build", "--release"])
      end

      yield bin_file
    end
  end

  private def tar
    tar_file = "#{basename}.tar"
    clean_project do |project|
      Process.run("tar", ["cvf", tar_file, project])
      yield tar_file
    ensure
      FileUtils.rm_rf(tar_file)
    end
  end

  private def tar_gz
    tar_file = "#{basename}.tar.gz"
    clean_project do |project|
      Process.run("tar", ["czvf", tar_file, project])
      yield tar_file
    ensure
      FileUtils.rm_rf(tar_file)
    end
  end

  private def tar_bz2
    tar_file = "#{basename}.tar.bz2"
    clean_project do |project|
      Process.run("tar", ["cjvf", tar_file, project])
      yield tar_file
    ensure
      FileUtils.rm_rf(tar_file)
    end
  end

  private def zip
    zip_file = "#{basename}.zip"
    clean_project do |project|
      Process.run("zip", ["-r", zip_file, project])
      yield zip_file
    ensure
      FileUtils.rm_rf(zip_file)
    end
  end

  private def clean_project
    clean do
      basename = self.basename
      Process.run("git", ["clone", "--single-branch", "--branch", tag, ".", "/tmp/#{basename}"])
      FileUtils.rm_rf("/tmp/#{basename}/.git")
      FileUtils.cd("/tmp") do
        yield basename
      end

    ensure
      FileUtils.rm_rf("/tmp/#{basename}")
    end
  end

  private def release
    client.get("#{project_path}/releases/#{tag}") do |response|
      raise response.body_io.gets_to_end unless response.success?
      Release.from_json(response.body_io)
    ensure
      response.body_io.skip_to_end
    end
  end

  private def basename
    "autopass.cr-#{tag}"
  end

  private def tag
    @tag ||= `git describe --tags`.chomp
  end

  private def last_tag
    `git tag`.lines[-2].chomp
  end

  private def description
    @description ||= `git log --format='- %s' #{last_tag}..#{tag}`
  end

  private def upload_file(path, content_type)
    IO.pipe do |reader, writer|
      channel = Channel(String).new(1)

      spawn do
        HTTP::FormData.build(writer) do |builder|
          channel.send(builder.content_type)

          File.open(path) do |file|
            metadata = HTTP::FormData::FileMetadata.new(filename: File.basename(path))
            headers = HTTP::Headers{"Content-Type" => content_type}
            builder.file("file", file, metadata, headers)
          end
        end

        writer.close
      end

      headers = HTTP::Headers{"Content-Type" => channel.receive}

      client.post("#{project_path}/uploads", body: reader, headers: headers) do |response|
        raise response.body_io.gets_to_end unless response.success?
        Upload.from_json(response.body_io)
      ensure
        response.body_io.skip_to_end
      end
    end
  end

  private def project_path
    "/api/v4/projects/#{URI.encode_www_form(PROJECT_NAME)}"
  end

  private def clean
    begin
      Process.run("git", %w[stash, -u])
      yield
    ensure
      Process.run("git", %w[stash, pop])
    end
  end
end

Releaser.new.create_release
