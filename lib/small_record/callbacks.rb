module SmallRecord
  module Callbacks
    extend ActiveSupport::Concern

    depends_on ActiveSupport::Callbacks

    included do
      define_callbacks \
        :before_init,    :after_init,
        :before_find,    :after_find,
        :before_save,    :after_save,
        :before_create,  :after_create,
        :before_update,  :after_update,
        :before_destroy, :after_destroy
    end

    module InstanceMethods
      def run_callbacks_chain(kind)
        return false if false == run_callbacks("before_#{kind}") { |result, object| result == false }
        yield.tap do
          run_callbacks "after_#{kind}"
        end
      end
    end
  end
end
