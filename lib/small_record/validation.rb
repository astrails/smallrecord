module SmallRecord
  class RecordInvalidError < StandardError
    attr_reader :record
    def initialize(record)
      @record = record
      super("Invalid record: #{@record.errors.full_messages.to_sentence}")
    end
  end

  module Validation

    extend ActiveSupport::Concern
    depends_on ActiveModel::Validations

    included do
      define_callbacks :before_validation
      define_callbacks :before_validation_on_create
      define_callbacks :before_validation_on_update
    end

    module ClassMethods
      def create!(data = {}, &block)
        if data.is_a?(Array)
          data.map { |d| create!(d, &block) }
        else
          returning new(data, &block), &:save!
        end
      end
    end

    module InstanceMethods
      def save
        if valid?
          super
        else
          false
        end
      end

      def save!
        save || raise(RecordInvalidError, self)
      end
    end

    def valid?
      return false if false == run_callbacks(:before_validation)
      return false if false == run_callbacks(new_record? ? :before_validation_on_create : :before_validation_on_update)
      super
    end
  end
end