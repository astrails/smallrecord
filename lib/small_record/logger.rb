module SmallRecord
  module Logger
    extend ActiveSupport::Concern
    included do
      # cattr_accessor :logger, :instance_writer => false
      @@colorize_logging = true
      cattr_accessor :colorize_logging, :instance_writer => false
    end

    module ClassMethods
      def log(str, action = nil)
        if block_given?
          if logger and logger.level <= 1
            result = nil
            seconds = Benchmark.realtime { result = yield }
            _log(str, "#{name} #{action}", seconds)
            result
          else
            yield
          end
        else
          _log(str, name, 0)
          nil
        end
      rescue Exception => e
        # Log message and raise exception.
        # Set last_verfication to 0, so that connection gets verified
        # upon reentering the request loop
        @last_verification = 0
        message = "#{e.class.name}: #{e.message}: #{str}"
        _log(message, name, 0)
        raise e
      end

      def log_bug(message)
        log_error "\n\nBUG: #{message}\n\nat #{caller[0..10]*"\n"}\n\n"
      end

      def log_error(message)
        if message.is_a?(Exception)
          logger.fatal format_error_message("\n#{message.class} (#{message}): #{message.backtrace.first}")

          backtrace = defined?(Rails) && Rails.respond_to?(:backtrace_cleaner) ?
            Rails.backtrace_cleaner.clean(message.backtrace) : message.backtrace

          logger.debug format_debug_message(backtrace.join("\n  "))
        else
          logger.error format_error_message(message)
        end
      end

      def log_warn(message)
        logger.warn format_warning_message(message)
      end

      def log_debug(message)
        logger.debug format_debug_message(message)
      end

      def log_and_raise_error(message)
        log_error message
        raise message
      end

      protected
      def _log(str, name, runtime)
        return unless logger

        logger.debug(
          format_log_entry(
            "#{name || "SR"} (#{sprintf("%f", runtime)})",
            str.gsub(/ +/, " ")
          )
        )
      end

      @@row_even = true
      def format_log_entry(message, dump = nil)
        if colorize_logging
          if @@row_even
            @@row_even = false
            message_color, dump_color = "4;36;1", "0;1"
          else
            @@row_even = true
            message_color, dump_color = "4;35;1", "0"
          end

          log_entry = "  \e[#{message_color}m#{message}\e[0m   "
          log_entry << "\e[#{dump_color}m%#{String === dump ? 's' : 'p'}\e[0m" % dump if dump
          log_entry
        else
          "%s  %s" % [message, dump]
        end
      end

      def format_error_message(message)
        # bold black on red
        "\e[1;30;41m#{message}\e[0m"
      end

      def format_warning_message(message)
        # bold yellow
        "\e[1;33m#{message}\e[0m"
      end

      def format_debug_message(message)
        # faint, white on black
        "\e[2;37;40m#{message}\e[0m"
      end
    end

    module InstanceMethods
      def log_error(message)
        self.class.log_error(message)
      end

      def log_and_raise_error(message)
        self.class.log_and_raise_error message
      end

      def log_warn(message)
        self.class.log_warn(message)
      end

      def log_debug(message)
        self.class.log_debug(message)
      end

      $tbd_times = Hash.new(1.year.ago.utc)
      def tbd(message = nil, period = 1.hour)
        key = Kernel.caller.first

        return if $tbd_times[key] > period.ago.utc
        $tbd_times[key] = Time.now.utc

        if message
          log_warn "TBD: #{caller.first} #{message}"
        else
          log_warn "TBD: #{caller.first}"
        end
      end

    end

  end
end