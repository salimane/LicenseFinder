module LicenseFinder
  module CLI
    class Base < Thor

      def self.auditable
        method_option :who, desc: "The person making this decision"
        method_option :why, desc: "The reason for making this decision"
        method_option :when, desc: "The time the decision was made"
      end

      no_commands do
        def decisions
          @decisions ||= Decisions.saved!(config.file)
        end
      end

      private

      def say_each(coll)
        if coll.any?
          coll.each do |item|
            say(block_given? ? yield(item) : item)
          end
        else
          say '(none)'
        end
      end

      def config
        @config ||= Configuration.with_optional_flags(options)
      end

      def txn
        @txn ||= {
          who:  options[:who],
          why:  options[:why],
          when: (options[:when] && Time.parse(options[:when]).getutc) || Time.now.getutc
        }
      end
    end
  end
end
