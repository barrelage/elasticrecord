module ElasticRecord

  # Generic error class.
  class ElasticRecordError < StandardError
  end

  # Raised by unsafe persistence methods when the record is invalid.
  class RecordInvalid < ElasticRecordError

    attr_reader :record

    def initialize record
      @record = record
      super I18n.t(
        :"#{@record.class.i18n_scope}.errors.messages.record_invalid",
        errors: @record.errors.full_messages.join(', '),
        default: :"errors.messages.record_invalid"
      )
    end

  end

end
