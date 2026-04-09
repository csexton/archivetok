require "yaml"
require "fileutils"

module Archivetok
  Config = Struct.new(:output_dir, :json_sidecar, :pages,
                      :filename_username, :filename_date, :filename_id, :filename_slug,
                      keyword_init: true) do
    def self.load(cli_options = {})
      yaml = load_yaml_config
      raw_dir = cli_options[:output_dir] || yaml["output_dir"] || Dir.pwd
      new(
        output_dir:        File.expand_path(raw_dir),
        json_sidecar:      cli_options.fetch(:json_sidecar, yaml["json_sidecar"] || false),
        pages:             (cli_options[:pages] || yaml["pages"] || 1).to_i,
        filename_username: cli_options.fetch(:filename_username, yaml.fetch("filename_username", true)),
        filename_date:     cli_options.fetch(:filename_date,     yaml.fetch("filename_date",     true)),
        filename_id:       cli_options.fetch(:filename_id,       yaml.fetch("filename_id",       false)),
        filename_slug:     cli_options.fetch(:filename_slug,     yaml.fetch("filename_slug",     true))
      )
    end

    def self.load_yaml_config
      candidates = [
        File.join(Dir.pwd, ".archivetok.yml"),
        File.expand_path("~/.archivetok.yml")
      ]
      path = candidates.find { |f| File.exist?(f) }
      path ? YAML.safe_load_file(path) || {} : {}
    end
  end
end
