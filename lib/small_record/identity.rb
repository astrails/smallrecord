module SmallRecord
  module Identity
    extend ActiveSupport::Concern

    included do
      attr_accessor :id
    end

    module ClassMethods
      # Indicate what kind of key (id) the model will have: uuid, natural, etc.
      # You can implement your own key types.
      #
      # @param [:uuid, :natural] the type of key
      # @param the options you want to pass along to the key factory (like :attributes => :name, for a natural key).
      #
      def key(name_or_factory = :uuid, *options)
        key_factory_class = name_or_factory.to_s.classify.constantize rescue name_or_factory
        @key_factory = key_factory_class.new(*options)
      end

      def key_factory
        @key_factory ||= Uuid.new
      end

      def next_key(object = nil)
        returning(key_factory.next_key(object)) do |key|
          raise "Keys may not be nil" if key.nil?
        end
      end

      def parse_key(string)
        key_factory.from_string(string) rescue string
      end
    end

    module InstanceMethods

      def ==(comparison_object)
        comparison_object.equal?(self) ||
          (comparison_object.instance_of?(self.class) &&
            comparison_object.id == id &&
            !new_record? &&
            !comparison_object.new_record?)
      end

      def eql?(comparison_object)
        self == (comparison_object)
      end

      def hash
        id.to_s.hash
      end

      def to_param
        id.to_param
      end

      def parse_key(string)
        self.class.parse_key(string)
      end
    end
  end
end