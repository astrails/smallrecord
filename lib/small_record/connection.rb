module SmallRecord
  module Connection
    extend ActiveSupport::Concern

    module ClassMethods
      def connection_configuration_path
        File.join(RAILS_ROOT, "config", "small_record.yml")
      end

      def connection_configuration(environment)
        @connection_configuration ||= YAML.load(File.read(connection_configuration_path)).with_indifferent_access
        @connection_configuration[environment] || {}
      end

      def establish_connection(config = connection_configuration(RAILS_ENV))
        @connection = case(adapter = config[:adapter].to_s)
        when "", "Cassandra", "cassandra"
          raise("no keyspace in the connfiguration file") unless config[:keyspace]
          host = config[:host] || '127.0.0.1'
          port = config[:port] || 9160
          timeout = config[:timeout] || 2
          Cassandra.new(config[:keyspace], "#{host}:#{port}", :timeouts => Hash.new(timeout))
        else
          klass = adapter.classify
          klass = "SmallRecord::#{klass}" unless klass.starts_with?("::")

          klass.constantize.new(config)
        end
      end

      def connection
        @connection || establish_connection
      end
    end

    module InstanceMethods
      def connection
        self.class.connection
      end
    end
  end
end

