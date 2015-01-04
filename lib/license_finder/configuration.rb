module LicenseFinder
  class Configuration
    def self.with_optional_flags(flags, project_path = Pathname.new('.'))
      new(flags, project_path)
    end

    def initialize(flags, project_path)
      @config_file = project_path.join('config', 'license_finder.yml')
      configuration = config_file.exist? ? YAML.load(config_file.read) : {}
      configuration = {} unless configuration
      @flags = flags
      @configuration = configuration
    end

    def gradle_command
      get(:gradle_command) || "gradle"
    end

    def config_file
      @config_file
    end

    private

    def get(key)
      @flags[key.to_sym] || @configuration[key.to_s]
    end
  end
end
