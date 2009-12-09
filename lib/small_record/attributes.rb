ActiveSupport::JSON::Encoding.use_standard_json_time_format = true

module SmallRecord
  class Attribute
    # Get expected type out of a db presentation (string)
    CONVERTERS = {
      Date    => proc { |str| Date.strptime(str, "%Y/%m/%d") },
      Integer => proc { |str| Integer(str) },
      Float   => proc { |str| Float(str) },
      Time    => proc { |str| Time.xmlschema(str) },
      Symbol  => proc { |str| str.to_sym },
      JSON    => proc { |str| JSON.load(str) },
      SmallRecord::UUID => proc { |str| SmallRecord::UUID.parse(str) },
    }

    attr_reader :name
    def initialize(name, owner_class, options = {})
      @name = name.to_s
      @owner_class = owner_class
      @options = options
      @options[:null] = true unless @options.has_key?(:null)
      @options[:type] = case (_type = @options[:type])
      when :uuid
        SmallRecord::UUID
      when Symbol
        _type.to_s.classify.constantize
      when nil
        String
      else
        _type
      end

      # append_validations!
      define_methods!
    end

    # I think this should live somewhere in Amo
    def check_value!(value)
      # Allow nil and Strings to fall back on the validations for typecasting
      case value
      when nil, String, expected_type
        value
      else
        raise TypeError, "#{@name} expected #{expected_type.inspect} but got #{value.inspect}"
      end
    end

    def expected_type
      @options[:type] || String
    end

    def type_cast(value)
      if (nil == value) && @options[:null]
        return @options[:default]
      end
      if value.is_a?(expected_type)
        value
      elsif (converter = CONVERTERS[expected_type])
        converter.call(value) rescue value
      else
        value
      end
    end

    # FIXME: replace the following by running converters on all string values.
    #        - do not run on nil
    #        - decide what to do with ""
    # I don't think we need format validations
    # also formats are more restrictive then the underlying 'conversions'
    # For example we use Time.parse for datetime parsing which support a LOT of formats
    # FORMATS = {
    #   Date    => /^\d{4}\/\d{2}\/\d{2}$/,
    #   Integer => /^-?\d+$/,
    #   Float   => /^-?\d*\.\d*$/m
    #   Time    => /\A\s*
    #               -?\d+-\d\d-\d\d
    #               T
    #               \d\d:\d\d:\d\d
    #               (\.\d*)?
    #               (Z|[+-]\d\d:\d\d)?
    #               \s*\z/ix # lifted from the implementation of Time.xmlschema
    # }
    #
    # def append_validations!
    #   if f = FORMATS[expected_type]
    #     @owner_class.validates_format_of @name, :with => f, :unless => lambda {|obj| obj.send(name).is_a? expected_type }, :allow_nil => @options[:allow_nil]
    #   end
    # end

    def define_methods!
      @owner_class.define_attribute_methods(true)
    end
  end

  module Attributes
    extend ActiveSupport::Concern
    include ActiveModel::AttributeMethods

    included do
      class_inheritable_hash :model_attributes
      attribute_method_suffix("", "=")
      attr_reader :attributes
    end

    module ClassMethods
      def attribute(name, options = {})
        write_inheritable_hash(:model_attributes, {name.to_sym => Attribute.new(name, self, options)})
      end

      def attr_accessible(*attributes)
        write_inheritable_attribute(:attr_accessible, Set.new(attributes.map(&:to_s)) + (accessible_attributes || []))
      end

      def accessible_attributes # :nodoc:
        read_inheritable_attribute(:attr_accessible)
      end

      def define_attribute_methods(force = false)
        return unless model_attributes
        undefine_attribute_methods if force
        super(model_attributes.keys)
      end
    end

    module InstanceMethods
      def write_attribute(name, value)
        if ma = self.class.model_attributes[name.to_sym]
          value = ma.check_value!(value)
        end
        @attributes[name] = value
      end

      def read_attribute(name)
        if ma = self.class.model_attributes[name.to_sym]
          ma.type_cast(@attributes[name])
        else
          @attributes[name]
        end
      end

      def read_data(name)
        @data[name.to_s] ||= ActiveSupport::OrderedHash.new
      end

      def write_data_item(name, key, value)
        insert name.to_s => {key.to_s => value.to_json}
        read_data(name)[key.to_s] = value
      end

      def delete_data_item(name, key)
        delete name.to_s, key.to_s
        read_data(name).delete(key.to_s)
      end

      def attributes=(attributes)
        return if attributes.nil?

        attributes = remove_attributes_protected_from_mass_assignment(attributes)

        attributes.each do |(name, value)|
          send("#{name}=", value)
        end
      end

      def update_attributes(attributes)
        self.attributes = attributes
        save
      end

      def update_attributes!(attributes)
        self.attributes = attributes
        save!
      end

      protected
      def attribute_method?(name)
        @attributes.include?(name.to_sym) || model_attributes[name.to_sym]
      end

      private
      def attribute(name)
        read_attribute(name.to_sym)
      end

      def attribute=(name, value)
        write_attribute(name.to_sym, value)
      end

      def attributes_protected_by_default
        ['id']
      end

      def remove_attributes_protected_from_mass_assignment(attributes)
        safe_attributes =
          if self.class.accessible_attributes.nil?
            attributes.reject { |key, value| attributes_protected_by_default.include?(key.to_s) }
          else
            attributes.reject { |key, value|
              !self.class.accessible_attributes.include?(key.to_s) ||
               attributes_protected_by_default.include?(key.to_s) }
          end

        removed_attributes = attributes.keys - safe_attributes.keys

        if removed_attributes.any?
          log_protected_attribute_removal(removed_attributes)
        end

        safe_attributes
      end

      def log_protected_attribute_removal(*attributes)
        logger.debug "WARNING: Can't mass-assign these protected attributes: #{attributes.join(', ')}"
      end

    end
  end
end