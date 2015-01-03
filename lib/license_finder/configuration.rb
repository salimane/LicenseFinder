module LicenseFinder
  class Configuration
    def self.with_optional_saved_config(primary_config, project_path = Pathname.new('.'))
      config_file = project_path.join('config', 'license_finder.yml')
      saved_config = config_file.exist? ? YAML.load(config_file.read) : {}
      saved_config = {} unless saved_config
      new(primary_config, saved_config)
    end

    def initialize(primary_config, saved_config)
      @primary_config = primary_config
      @saved_config = saved_config
    end

    def gradle_command
      get(:gradle_command) || "gradle"
    end

    def decisions_file
      file_name = get(:decisions_file) || "doc/dependency_decisions.yml"
      Pathname(file_name)
    end

    def config_file
      Pathname.new('.').join('config', 'license_finder.yml')
    end

    private

    def get(key)
      @primary_config[key.to_sym] || @saved_config[key.to_s]
    end
  end
end
