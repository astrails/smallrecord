module SmallRecord
  class ReadOnlyRecord < SmallRecordError;end

  module Persistence
    extend ActiveSupport::Concern
    module ClassMethods

      def create(attrs = {}, &block)
        if attrs.is_a?(Array)
          attrs.map {|d| create(d, &block)}
        else
          returning new(attrs, &block), &:save
        end
      end

      def instantiate(id, attrs)
        returning allocate do |record|
          record.instantiate(id, attrs)
        end
      end

    end

    module InstanceMethods

      def initialize(attributes = {})
        run_callbacks_chain(:init) do
          @attributes = {}.with_indifferent_access
          self.attributes = attributes

          @data = ActiveSupport::OrderedHash.new

          yield(self) if block_given?

          @new_record = true
        end
      end

      def instantiate(id, data)
        run_callbacks_chain(:find) do
          @id = parse_key(id)
          @data = decode_hash(data)
          @attributes = (@data.delete('attributes') || {}).with_indifferent_access
        end
        self
      end

      def readonly?
        @readonly == true
      end

      def readonly!
        @readonly = true
      end

      def new_record?
        @new_record || false
      end

      def save
        create_or_update
      end

      def destroy(*args)
        run_callbacks_chain(:destroy) do
          delete(*args) unless new_record?
          true
        end
      end

      protected
      def encode_hash(hash)
        hash.inject({}) do |res, (k, v)|
          res[k.to_s] = ActiveSupport::JSON.encode(v)
          res
        end
      end

      def encode_data(hash)
        hash.inject({}) do |res, (k, v)|
          res[k.to_s] = encode_hash(v)
          res
        end
      end

      def decode_hash(hash)
        hash.inject(ActiveSupport::OrderedHash.new) do |res, (k, v)|
          res[k.to_s] = v.is_a?(Hash) ? decode_hash(v) : ActiveSupport::JSON.decode(v)
          res
        end
      end

      def data_for_update
        returning({}) do |data|
          attributes = @attributes.slice(*changed)
          data["attributes"] = attributes unless attributes.empty?
        end
      end

      def update(*args)
        run_callbacks_chain(:update) do
          data = data_for_update

          # for an existing record don't write if nothing changed
          unless !new_record? && data.empty?
            (data["attributes"] ||= {})["schema_version"] = schema_version
            # TODO: updated_at
            # FIXME: how to handle dirty non-attribute subhashes?
            insert(encode_data(data), *args)
          end
          true
        end
      end

      def create
        run_callbacks_chain(:create) do
          @id ||= self.class.next_key(self)
          update.tap do|res|
            @new_record = false if res
          end
        end
      end

      def create_or_update
        run_callbacks_chain(:save) do
          raise ReadOnlyRecord, self if readonly?
          new_record? ? create : update
        end
      end

    end
  end
end
