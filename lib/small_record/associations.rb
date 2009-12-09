require 'small_record/associations/association_proxy'
require 'small_record/associations/has_many_association'
module SmallRecord
  module Associations
    extend ActiveSupport::Concern

    included do
      class_inheritable_hash :associations
    end

    module ClassMethods
      def has_many(association_name, options = {}) # TODO: add extensions block
        write_inheritable_hash(:associations,
         {association_name => HasManyAssociation.new(association_name, self, options)})
      end
    end
  end
end
