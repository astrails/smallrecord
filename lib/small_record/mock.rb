module SmallRecord
  class Mock

    @@data = {}
    cattr_reader :data

    def initialize(*_)
    end

    def inspect
      "SmallRecord::Mock(\n #{@@data.pretty_inspect}\n)"
    end

    def get_range(table_name, opts)
      returning(table(table_name).keys) do |res|
        res.reject! {|x| x < opts[:start]} if opts[:start]
        res.slice!(opts[:count], res.size) if opts[:count]
      end
    end

    def get(table_name, id, *args)
      table(table_name)[id.to_s]
    end

    def multi_get(table_name, ids, *args)
      table(table_name).slice(*ids)
    end

    def count_range(table_name, opts)
      get_range(table_name, opts).size
    end

    def insert(table_name, id, hash, opts)
      table(table_name).deep_merge!(id => hash)
    end

    def remove(table_name, id, *args)
      column, subcolumn, _ = args
      h = table(table_name)
      key = id

      if column
        h = h[key]
        key = column
        if subcolumn
          h = h[key]
          key = subcolumn
        end
      end

      h.delete(key)
    end

    def clear_column_family!(table_name, opts = {})
      table(table_name).clear
    end

    def clear_keyspace!(opts = {})
      @@data.clear
    end


    protected
    def table(table_name)
      @@data[table_name] ||= {}
    end
  end
end