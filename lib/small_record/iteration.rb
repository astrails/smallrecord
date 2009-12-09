module SmallRecord
  module Iteration
    extend ActiveSupport::Concern

    module ClassMethods

      # extend ActiveSupport::Concern
      # depends_on Enumerable
      include Enumerable # FIXME: do we really need it????! we might get much more then we need :)
                         # TODO: can we selectively get only what we need?

      # FIXME: args passing
      def each(opts = {}, &block)
        start = opts.delete(:start)
        step = opts.delete(:step) || 200
        while (start = (slice = iterate(start, :count => step)).last)
          find_many(slice).each(&block)
        end
      end

      protected
      def iterate(start, opts = {})
        returning(get_range(opts.merge(:start => start || ""))) do |slice|
          slice.shift if start
        end
      end
    end
  end
end