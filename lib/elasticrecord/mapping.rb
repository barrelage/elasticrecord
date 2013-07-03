module ElasticRecord
  # Methods related to inspecting and defining mappings, as well as typecasting
  # properties during serialization and deserialization.
  module Mapping

    attr_writer :index_name

    def index_name
      @index_name ||= model_name.plural
    end

    def type_name
      @type_name ||= model_name.singular
    end

    def mapping &block
      if block_given?
        yield
        update_mapping
      else
        @mapping ||= { properties: properties }
      end
    end

    %w[ dynamic _id _size _timestamp _ttl ].each do |name|
      define_method(name) { |value| mapping[name] = value }
    end

    def properties *props
      return (@properties ||= {}) if props.empty?
      props.each { |prop| property prop }
    end

    def property prop, options = {}
      prop = prop.to_sym

      properties[prop] = {
        type: 'string',
        index: 'not_analyzed'
      }.merge options

      define_attribute_methods [ prop ]
      instance_variable_set :@attribute_methods_generated, nil

      prop_methods = Module.new
      prop_methods.class_eval <<-RUBY, __FILE__, __LINE__ + 1
        def #{prop}
          self[:#{prop}]
        end

        def #{prop}= value
          self[:#{prop}] = value && self.class.typecast(:#{prop}, value)
        end

        def #{prop}?
          !!self[:#{prop}]
        end
      RUBY

      include prop_methods
    end

    def type name, &block
      types[name.to_sym] = block
    end

    def types
      @types ||= Hash.new -> value { value }
    end

    def typecast prop, value
      type = properties[prop.to_sym].try(:[], :type).try(:to_sym)
      types[type].call value
    end

  end
end
