module ElasticRecord
  # Methods related to record persistence in ElasticSearch.
  module Persistence

    class << self

      def included base
        base.extend ClassMethods
      end

    end

    # Class methods related to record persistence.
    module ClassMethods

      def init_with attributes
        record = new attributes
        record.instance_variable_set :@new_record, false
        record
      end

    end

    def persisted?
      !@new_record && !@destroyed
    end

    def new_record?
      @new_record
    end

    def destroyed?
      @destroyed
    end

  end
end
