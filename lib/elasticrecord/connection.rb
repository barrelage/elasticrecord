require 'connection_pool'
require 'stretcher'

module ElasticRecord
  module Connection

    def connection
      Thread.current[:"current-#{object_id}"] ||= connection_pool.checkout
    end

    def connection_pool
      @connection_pool || establish_connection
    end

    def establish_connection options = {}
      url     = options.fetch(:url, 'http://localhost:9200')
      pool    = options.fetch(:pool, 5)
      timeout = options.fetch(:timeout, 5)

      @connection_pool.shutdown if @connection_pool
      @connection_pool = ConnectionPool.new(size: pool, timeout: timeout) do
        Stretcher::Server.new url
      end
    end

    def with_connection &block
      connection_pool.with &block
    end

    def with_index &block
      connection_pool.with do |conn|
        yield conn.index(index_name)
      end
    end

    def with_type &block
      connection_pool.with do |conn|
        yield conn.index(index_name).type(type_name)
      end
    end

  end
end
