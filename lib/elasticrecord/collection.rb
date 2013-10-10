module ElasticRecord
  class Collection < Delegator

    attr_reader :klass
    attr_accessor :page, :per_page

    delegate :model_name, to: :klass

    delegate :results, :total, :facets, :raw, to: :response
    delegate :took, :timed_out, to: :raw

    PER_PAGE = 20

    def initialize klass, type, body
      @klass = klass
      @type  = type
      @body  = body
    end

    def response
      @response ||= @type.search(body).tap do |response|
        response.results.map!{ |result| klass.init_with result }
      end
    end

    def paginate params
      params.each do |param, value|
        self.send("#{param}=", value) if self.respond_to? "#{param}="
      end

      self
    end

    def body
      pagination.merge(@body)
    end

    def from
      return 0 unless page > 1
      (page - 1) * per_page
    end

    def page
      @page || 1
    end

    def page= number
      @page = number.to_i
    end

    def per_page
      @per_page || PER_PAGE
    end

    def per_page= count
      @per_page = count.to_i
    end

    def __getobj__
      results
    end

    private

    def pagination
      { size: per_page, from: from }
    end

  end
end
