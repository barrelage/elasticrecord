require 'active_model'
require 'elasticrecord/connection'
require 'elasticrecord/mapping'
require 'elasticrecord/querying'
require 'elasticrecord/persistence'

module ElasticRecord
  class Base

    extend ActiveModel::Callbacks
    extend ActiveModel::Translation
    include ActiveModel::Model
    include ActiveModel::Dirty
    include ActiveModel::Serialization
    include ActiveModel::Serializers::JSON

    extend ElasticRecord::Connection
    extend ElasticRecord::Mapping
    extend ElasticRecord::Querying
    include ElasticRecord::Persistence

    class << self

      def create attrs
        new(attrs).tap(&:save)
      end

      def i18n_scope
        :activerecord
      end

      def update_mapping
        with_index do |index|
          if index.exists?
            index.type(type_name).put_mapping type_name => mapping
          else
            index.create mappings: { type_name => mapping }
          end
        end
      end

      def inherited subclass
        subclass.instance_variable_set :"@connection_pool", @connection_pool
        subclass.instance_variable_set :"@mapping", @mapping
        subclass.instance_variable_set :"@properties", @properties
        subclass.instance_variable_set :"@types", @types
      end

    end

    define_model_callbacks :create, :update, :save, :destroy

    attr_reader :attributes, :meta

    type(:date) do |value|
      next value if value.acts_like? :time
      value and Time.iso8601 value
    end

    def initialize params = {}
      @attributes, @meta = Hashie::Mash.new, Hashie::Mash.new
      @new_record, @destroyed = true, false
      self.attributes = params
    end

    #--
    # attributes
    #++

    def attributes= params
      params ||= {}
      params.each do |attr, value|
        if respond_to? "#{attr}="
          public_send "#{attr}=", value
        else
          write_attribute attr, value
        end
      end
    end

    def read_attribute attr
      attributes[attr]
    end
    alias [] read_attribute

    def write_attribute attr, value
      return meta[attr] = value if attr.to_s.starts_with? '_'
      attribute_will_change! attr.to_s unless value == self[attr]
      attributes[attr] = value
    end
    alias []= write_attribute

    #--
    # other
    #++

    delegate :_id, :_timestamp, :_score, :_version, to: :meta
    alias_method :id, :_id
    alias_method :created_at, :_timestamp

    def == other
      other.instance_of?(self.class) && attributes == other.attributes
    end

    def inspect
      "#<%s%s>" % [
        self.class.name,
        attributes.map { |k, v| " #{k}: #{v.inspect}" }.join(',')
      ]
    end

    def destroy
      return false unless id.present?
      run_callbacks(:destroy) { remove }
      true
    end

    def save
      return false unless valid?
      run_callbacks :save do
        run_callbacks(new_record? ? :create : :update) { persist }
      end
      true
    end

    def update_attributes attrs
      self.attributes = attrs
      save
    end

    private

    alias attribute read_attribute

    #--
    # persistence
    #++

    def persist
      with_connection do |conn|
        if id
          conn.put id, attributes
        else
          self.attributes = conn.post(attributes).except('ok')
        end
      end
      @new_record = false
    end

    def remove
      with_connection { |conn| conn.delete id }
      @destroyed = true
    end

    def with_connection &block
      self.class.with_type &block
    end

  end
end
