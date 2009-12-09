module SmallRecord
  module Migrations
    extend ActiveSupport::Concern
    included do
      cattr_accessor :migration_column_name
      self.migration_column_name = :schema_version
      class_inheritable_array :migrations
      class_inheritable_accessor :current_schema_version
      self.current_schema_version = 0
    end

    class Migration
      attr_reader :version
      def initialize(version, block)
        @version = version
        @block = block
      end

      def run(attrs)
        @block.call(attrs)
        attrs
      end
    end

    class MigrationNotFoundError < StandardError
      def initialize(record_version, migrations)
        super("Cannot migrate a record from #{record_version.inspect}.  Migrations exist for #{migrations.map(&:version)}")
      end
    end

    module ClassMethods
      def migrate(version, &blk)
        write_inheritable_array(:migrations, [Migration.new(version, blk)])

        if version > self.current_schema_version
          self.current_schema_version = version
        end
      end

      def instantiate(key, data)

        # need migrations?
        @schema_version = data["attributes"].try(:delete, migration_column_name.to_s)
        if @schema_version.to_i == current_schema_version
          return super(key, data)
        end

        # find migrations to run
        versions_to_migrate = ((@schema_version.to_i + 1)..current_schema_version)
        migrations_to_run = versions_to_migrate.map do |v|
          # FIXME: hash here
          migrations.find {|m| m.version == v}
        end

        # preserve original attributes for 'dirty' comparison
        attr_orig = (data['attributes'] || {}).dup

        # migrate
        data = migrations_to_run.inject(data) do |d, migration|
          migration.run(d)
        end

        # instantiate and update 'changed'
        returning super(key, data) do |record|
          record.attributes_changed!(attr_orig.diff(record.attributes).keys)
        end
      end
    end

    module InstanceMethods
      def schema_version
        Integer(@schema_version || self.class.current_schema_version)
      end
    end

  end
end