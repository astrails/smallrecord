module SmallRecord
  module Dump
    extend ActiveSupport::Concern

    module ClassMethods

      def dump(opts = {})
        start = opts.delete(:start)
        step = opts.delete(:step) || 200
        puts "{"
        while (start = (slice = iterate(start, :count => step)).last)
          puts " " << unordered_hash(multi_get(slice)).pretty_inspect[1..-3] <<  ","
        end
        puts "}"
      end

    end
  end
end

def unordered_hash(h)
  h.inject({}) do |res, (k,v)|
    res[k] = v.is_a?(Hash) ? unordered_hash(v) : v
    res
  end
end