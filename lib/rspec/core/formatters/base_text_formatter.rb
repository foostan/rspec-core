RSpec::Support.require_rspec_core "formatters/base_formatter"
RSpec::Support.require_rspec_core "formatters/console_codes"

module RSpec
  module Core
    module Formatters

      # Base for all of RSpec's built-in formatters. See RSpec::Core::Formatters::BaseFormatter
      # to learn more about all of the methods called by the reporter.
      #
      # @see RSpec::Core::Formatters::BaseFormatter
      # @see RSpec::Core::Reporter
      class BaseTextFormatter < BaseFormatter
        Formatters.register self, :message, :dump_summary, :dump_failures,
                                  :dump_pending, :seed

        # @method message
        # @api public
        #
        # Used by the reporter to send messages to the output stream.
        #
        # @param notification [MessageNotification] containing message
        def message(notification)
          output.puts notification.message
        end

        # @method dump_failures
        # @api public
        #
        # Dumps detailed information about each example failure.
        #
        # @param notification [NullNotification]
        def dump_failures(notification)
          return if failed_example_notifications.empty?
          output.puts
          output.puts "Failures:"
          failed_example_notifications.each_with_index do |failure, index|
            output.puts
            output.puts "#{short_padding}#{index.next}) #{failure.description}"
            failure.colorized_message_lines(ConsoleCodes).each do |line|
              output.puts "#{long_padding}#{line}"
            end
            failure.colorized_formatted_backtrace(ConsoleCodes).each do |line|
              output.puts "#{long_padding}#{line}"
            end
          end
        end

        # @method dump_summary
        # @api public
        #
        # This method is invoked after the dumping of examples and failures. Each parameter
        # is assigned to a corresponding attribute.
        #
        # @param summary [SummaryNotification] containing duration, example_count,
        #                                      failure_count and pending_count
        def dump_summary(summary)
          dump_profile unless mute_profile_output?(summary.failure_count)
          output.puts "\nFinished in #{format_duration(summary.duration)}" +
                      " (files took #{format_duration(summary.load_time)} to load)\n"
          output.puts summary.colorize_with ConsoleCodes
          dump_commands_to_rerun_failed_examples
        end

        # @api public
        #
        # Outputs commands which can be used to re-run failed examples.
        #
        def dump_commands_to_rerun_failed_examples
          return if failed_examples.empty?
          output.puts
          output.puts("Failed examples:")
          output.puts

          failed_examples.each do |example|
            output.puts(failure_color("rspec #{RSpec::Core::Metadata::relative_path(example.location)}") + " " + detail_color("# #{example.full_description}"))
          end
        end

        # @api public
        #
        # Outputs the slowest examples and example groups in a report when using `--profile COUNT` (default 10).
        #
        def dump_profile
          dump_profile_slowest_examples
          dump_profile_slowest_example_groups
        end

        # @private
        def dump_profile_slowest_examples
          sorted_examples = slowest_examples

          time_taken = sorted_examples[:slows] / sorted_examples[:total]
          percentage = '%.1f' % ((time_taken.nan? ? 0.0 : time_taken) * 100)

          output.puts "\nTop #{sorted_examples[:examples].size} slowest examples (#{format_seconds(sorted_examples[:slows])} seconds, #{percentage}% of total time):\n"

          sorted_examples[:examples].each do |example|
            output.puts "  #{example.full_description}"
            output.puts "    #{bold(format_seconds(example.execution_result.run_time))} #{bold("seconds")} #{format_caller(example.location)}"
          end
        end

        # @private
        def dump_profile_slowest_example_groups

          sorted_groups = slowest_groups
          return if sorted_groups.empty?

          output.puts "\nTop #{sorted_groups.size} slowest example groups:"
          slowest_groups.each do |loc, hash|
            average = "#{bold(format_seconds(hash[:average]))} #{bold("seconds")} average"
            total   = "#{format_seconds(hash[:total_time])} seconds"
            count   = pluralize(hash[:count], "example")
            output.puts "  #{hash[:description]}"
            output.puts "    #{average} (#{total} / #{count}) #{loc}"
          end
        end

        # @private
        def dump_pending(notification)
          unless pending_examples.empty?
            output.puts
            output.puts "Pending:"
            pending_examples.each do |pending_example|
              output.puts pending_color("  #{pending_example.full_description}")
              output.puts detail_color("    # #{pending_example.execution_result.pending_message}")
              output.puts detail_color("    # #{format_caller(pending_example.location)}")
            end
          end
        end

        # @private
        def seed(notification)
          return unless notification.seed_used?
          output.puts
          output.puts "Randomized with seed #{notification.seed}"
          output.puts
        end

        # @api public
        #
        # Invoked at the very end, `close` allows the formatter to clean
        # up resources, e.g. open streams, etc.
        #
        # @param notification [NullNotification]
        def close(notification)
          output.close if IO === output && output != $stdout
        end

      protected

        def bold(text)
          ConsoleCodes.wrap(text, :bold)
        end

        def color(text, color_code)
          ConsoleCodes.wrap(text, color_code)
        end

        def failure_color(text)
          color(text, RSpec.configuration.failure_color)
        end

        def success_color(text)
          color(text, RSpec.configuration.success_color)
        end

        def pending_color(text)
          color(text, RSpec.configuration.pending_color)
        end

        def fixed_color(text)
          color(text, RSpec.configuration.fixed_color)
        end

        def detail_color(text)
          color(text, RSpec.configuration.detail_color)
        end

        def default_color(text)
          color(text, RSpec.configuration.default_color)
        end

        def short_padding
          '  '
        end

        def long_padding
          '     '
        end

      private

        def format_caller(caller_info)
          configuration.backtrace_formatter.backtrace_line(caller_info.to_s.split(':in `block').first)
        end

      end
    end
  end
end
