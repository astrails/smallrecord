module SmallRecord
  module Associations
    class HasManyAssociation
      def initialize(association_name, owner_class, options)
        @association_name, @owner_class, @options = association_name, owner_class, options
        associate!
      end

      def associate!
        code = <<-RUBY
          def #{@association_name}
            @#{@association_name} ||= self.class.associations[:#{@association_name}].proxy(self)
          end

          def create_#{@association_name.to_s.singularize}(*args)
            #{@association_name}.create(*args)
          end

          def #{@association_name.to_s.singularize}_ids
            self.class.associations[:#{@association_name}].collection_ids(self)
          end

        RUBY
        @owner_class.class_eval code
      end

      def proxy(owner)
        AssociationProxy.new(owner, self)
      end

      def find(proxy, ids)
        ids_to_find = [*ids].map(&:to_s)
        all_ids = collection_ids(proxy.proxy_owner)
        missing_ids = ids_to_find - all_ids
        unless missing_ids.empty?
          raise(RecordNotFound, "Couldn't find all #{@association_name} with IDs #{ids_to_find.inspect}. missing #{missing_ids.inspect}")
        end
        target_class.find(ids)
      end

      def first(proxy)
        id = collection_ids(proxy.proxy_owner).first
        id && target_class.find(id)
      end

      def last(proxy)
        id = collection_ids(proxy.proxy_owner).last
        id && target_class.find(id)
      end

      def all(proxy)
        collection(proxy.proxy_owner)
      end

      def find_target(proxy)
        collection(proxy.proxy_owner)
      end

      def create(proxy, attrs)
        owner = proxy.proxy_owner
        returning(target_class.new(attrs)) do |object|
          if proxy.loaded?
            if proxy.target
              proxy.target << object
            else
              proxy.target = [object]
            end
          end

          owner.save if owner.new_record? # we need 'id'

          if foreign_key = owner.id
            object.send "#{foreign_key_name}=", foreign_key
            if object.save
              # write though the assoc
              owner.write_data_item collection_attribute_name, object.id, 1
            end
          end
        end
      end

      def foreign_key_name
        "#{@owner_class.name.downcase.singularize}_id"
      end

      def collection_attribute_name
        "#{@association_name.to_s.singularize}_ids"
      end

      def target_class_name
        @association_name.to_s.classify
      end

      def target_class
        @target_class ||= target_class_name.constantize
      end

      def collection_ids(owner)
        owner.read_data(collection_attribute_name).keys
      end

      def collection(owner)
        target_class.find(collection_ids(owner))
      end

    end
  end
end
