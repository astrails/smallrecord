module SmallRecord
  module Associations
    class AssociationProxy

      alias_method :proxy_respond_to?, :respond_to?
      alias_method :proxy_extend, :extend
      instance_methods.each { |m| undef_method m unless m =~ /(^__|^nil\?$|^send$|proxy_)/ }

      def initialize(owner, association)
        @owner, @association = owner, association
      end

      def proxy_owner
        @owner
      end

      def first
        loaded? ? @target.first : @association.first(self)
      end

      def last
        loaded? ? @target.last : @association.last(self)
      end

      def all
        target
      end

      def find(ids)
        if loaded?
          ids_to_find = [ids].map(&:to_s)
          res = @target.find {|x| ids_to_find.include?(x.id.to_s) }
          ids.is_a?(Array) ? [*res] : res
        else
          @association.find(self, ids)
        end
      end

      def create(attrs = {})
        @association.create(self, attrs)
      end

      def respond_to?(symbol, include_priv = false)
        proxy_respond_to?(symbol, include_priv) || target.respond_to?(symbol, include_priv)
      end

      # Explicitly proxy === because the instance method removal above
      # doesn't catch it.
      def ===(other)
        target === other
      end

      def reset
        @loaded = false
        @target = nil
      end

      def reload
        reset
        load_target
      end

      def loaded?
        @loaded
      end

      def target
        loaded? ? @target : load_target
      end

      def target=(target)
        @target = target
        loaded
        @target
      end

      def inspect
        target.inspect
      end

      protected
      def method_missing(*args, &block)
        target.send *args, &block
      end

      def loaded
        @loaded = true
      end

      def load_target
        self.target = @owner.new_record? ? nil : @association.find_target(self)
      rescue SmallRecord::RecordNotFound
        reset
      end

    end

  end
end