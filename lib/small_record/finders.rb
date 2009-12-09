module SmallRecord
  class RecordNotFound < SmallRecordError;end

  module Finders
    extend ActiveSupport::Concern
    module ClassMethods

      def find(*args)
        case args.first
        when :first
          args.shift
          find_first(*args)
        when :last
          args.shift
          find_last(*args)
        when :all
          args.shift
          find_all(*args)
        when :many
          args.shift
          find_many(*args)
        else
          find_from_ids(*args)
        end
      end

      # FIXME: think though the args here
      # may be hand-pick-delete get_range args from "args"?
      def find_first(*args)
        id = get_range(:count => 1, *args).first
        id && find_one(id, *args)
      end
      alias :first :find_first

      def find_last(*args)
        id = get_range(:count => 1, :reversed => true, *args).first
        id && find_one(id, *args)
      end
      alias :last :find_last

      def find_all(*args)
        find_many(get_range(*args), *args)
      end
      alias :all :find_all

      def find_by_id(id, *args)
        find_single(id, *args)
      end

      def count(*args)
        count_range(*args)
      end

      protected

      # fetch single record
      # nil on failure or empty arg, no exceptions
      def find_single(id, *args)
        data = get(id.to_s, *args)
        return nil unless data && !data.empty?
        instantiate(id, data)
      end

      # fetch multiple records
      # [] if not found or empty args.
      def find_many(ids, *args)
        return [] if ids.blank?
        hashes = multi_get(ids.collect(&:to_s), *args)

        hashes.inject([]) do |res, (key, data)|
          res << instantiate(key, data) unless data.empty?
        end
      end

      def find_one(id, *args)
        find_single(id, *args) ||
          raise(RecordNotFound, "Couldn't find #{name} with ID=#{id}")
      end

      def find_some(ids, *args)
        expected_size = ids.size

        result = find_many(ids, *args)

        if result.size == expected_size
          result
        else
          raise(RecordNotFound, "Couldn't find all #{name.pluralize} with IDs #{ids.inspect} (found #{result.size} results, but was looking for #{expected_size})")
        end
      end

      def find_from_ids(*ids_and_options)
        expects_array = ids_and_options.first.kind_of?(Array)
        return [] if expects_array && ids_and_options.first.empty?

        options = ids_and_options.extract_options!
        ids = ids_and_options.flatten.compact.uniq
        case ids.size
        when 0
          raise(RecordNotFound, "Couldn't find #{name} without an ID")
        when 1
          result = find_one(ids.first, options)
          expects_array ? [ result ] : result
        else
          find_some(ids, options)
        end
      end

    end

  end
end