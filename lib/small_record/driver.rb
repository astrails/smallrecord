module SmallRecord
  module Driver
    extend ActiveSupport::Concern

    module ClassMethods
      def get(id, *args)
        log "GET #{id.inspect} (#{args.inspect})", "Get" do
          connection.get(table_name, id, *args)
        end
      end

      def get_range(opts = {})
        log "GET_RANGE(#{opts.inspect})", "GetRange" do
          connection.get_range(table_name, opts)
        end
      end

      def multi_get(ids, *args)
        log "multi_get(#{ids.inspect}, #{args.inspect})", "MultiGet" do
          connection.multi_get(table_name, ids, *args)
        end
      end

      def count_range(opts = {})
        log "count_range(#{opts.inspect})", "CountRange" do
          connection.count_range(table_name, opts)
        end
      end

      def insert(id, hash, opts = {})
        log "insert(#{id}, #{hash.inspect}, #{opts.inspect})", "Insert" do
          connection.insert(table_name, id, hash, opts)
        end
      end

      def delete(id, *args)
        log "delete(#{id}, #{args.inspect})", "Delete" do
          connection.remove(table_name, id, *args)
        end
      end

      def truncate(opts = {})
        log "truncate(#{opts.inspect})", "Truncate" do
          connection.clear_column_family!(table_name, opts)
        end
      end

      def truncate_all(opts = {})
        log "truncate_all(#{opts.inspect})", "TruncateAll" do
          connection.clear_keyspace!(opts)
        end
      end
    end

    module InstanceMethods
      def insert(hash, opts = {})
        self.class.insert(id.to_s, hash, opts)
      end

      def delete(*args)
        self.class.delete(id.to_s, *args)
      end
    end
  end
end