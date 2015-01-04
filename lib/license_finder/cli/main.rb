module LicenseFinder
  module CLI
    class Main < Base
      extend Rootcommand

      FORMATS = {
        'text' => TextReport,
        'html' => HtmlReport,
        'markdown' => MarkdownReport,
        'csv' => CsvReport
      }

      class_option :format, desc: "The desired output format.", default: 'text', enum: FORMATS.keys
      class_option :columns, type: :array, desc: "For CSV reports, which columns to print. Pick from: #{CsvReport::AVAILABLE_COLUMNS}", default: %w[name version licenses]
      class_option :gradle_command, desc: "Command to use when fetching gradle packages. Only meaningful if used with a Java/gradle project. Defaults to 'gradle'."

      method_option :quiet, type: :boolean, desc: "silences progress report"
      method_option :debug, type: :boolean, desc: "emit detailed info about what LicenseFinder is doing"
      desc "action_items", "List unapproved dependencies (the default action for `license_finder`)"
      def action_items
        unapproved = decision_applier.unapproved

        if unapproved.empty?
          say "All dependencies are approved for use", :green
        else
          say "Dependencies that need approval:", :red
          say report_of(unapproved)
          exit 1
        end
      end

      default_task :action_items

      desc "report", "Print a report of the project's dependencies to stdout"
      def report
        dependencies = decision_applier(Logger.new(quiet: true))
        say report_of(dependencies.acknowledged)
      end

      private

      # The core of the system. The saved decisions are applied to the current
      # packages.
      def decision_applier(logger = Logger.new(options))
        @decision_applier ||= DecisionApplier.new(
          decisions: decisions,
          packages: current_packages(logger)
        )
      end

      def current_packages(logger)
        PackageManager.current_packages(
          logger: logger,
          gradle_command: config.gradle_command,
          ignore_groups: decisions.ignored_groups
        )
      end

      def report_of(content)
        report = FORMATS[options[:format]]
        report.of(content, columns: options[:columns], project_name: decisions.project_name)
      end
    end
  end
end
