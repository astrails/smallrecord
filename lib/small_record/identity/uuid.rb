require 'uuidtools'
module SmallRecord
  class UUID < ::UUIDTools::UUID
    def to_json(*opts)
      to_s.to_json
    end
  end

  module Identity
    class Uuid
      # Next key takes an object and returns the key object it should use.
      # object will be ignored with synthetic keys but could be useful with natural ones
      def next_key(object)
        UUID.random_create
      end

      # from_param should create a new key object from the 'to_param' format
      def from_param(string)
        UUID.parse(string)
      end

      # from_string should create a new key object from the cassandra format.
      def from_string(string)
        UUID.parse(string)
      end
    end
  end
end