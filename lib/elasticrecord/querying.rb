module ElasticRecord
  module Querying

    def all limit = 20
      search size: limit
    end

    def count
      with_type do |type|
        type.search(size: 0).total
      end
    end

    def first
      all(1).first
    end

    def find id
      with_type do |type|
        raw = type.get id, true
        init_with raw._source.merge raw.except('_source', 'exists')
      end
    end

    def search(*args)
      with_type do |type|
        type.search(*args).results.map(&method(:init_with))
      end
    end

  end
end
