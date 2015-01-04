module LicenseFinder
  class Configuration
    def self.with_optional_flags(flags, project_path = Pathname.new('.'))
      new(flags, project_path)
    end

    def initialize(flags, project_path)
      @flags = flags
      @file = file
      init
      @configuration = YAML.load(file.read) || {}
    end

    def gradle_command
      get(:gradle_command) || "gradle"
    end

    def file
      @file || file_dir.join('license_finder.yml')
    end

    def init
      init! unless inited?
    end

    private

    def get(key)
      @flags[key.to_sym] || @configuration[key.to_s]
    end

    def inited?
      file.exist?
    end

    def init!
      file_dir.mkpath
      FileUtils.cp(file_template, file)
    end

    def file_dir
      Pathname.new('.').join('config')
    end

    def file_template
      ROOT_PATH.join('data', 'license_finder.example.yml')
    end
  end
end
