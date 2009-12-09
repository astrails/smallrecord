# TODO
# - still not clear if using supercolumns for attributes is a good idea
#   it might be a better idea to only use them for relationships...

module SmallRecord
  module Naming
    extend ActiveSupport::Concern

    module ClassMethods

      # set the table_name (column_family in cassandra-speak)
      def set_table_name(name)
        @table_name = name.to_s
      end

      def default_table_name
        name.downcase.pluralize
      end

      # returns table_name (aka column_family)
      # goes up in class hierarchy until it reaches a class
      # that is a direct descendant from SmallRecord::Base
      # this is so that all inherited classes will use same table_name
      def table_name
        @table_name ||= (superclass == SmallRecord::Base) ? default_table_name : superclass.table_name
      end

    end

    module InstanceMethods
      def table_name
        self.class.table_name
      end
    end
  end
end