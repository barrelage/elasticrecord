require 'elasticrecord'

RSpec.configure do |config|

  config.after :suite do
    TestRecord.with_index { |index| index.delete }
  end

end

class TestRecord < ElasticRecord::Base
  mapping do
    property :subject
    property :publish_at, type: :date
  end

  validates_presence_of :subject
  %w[
    after_initialize
    before_validation
    after_validation
    before_save
    after_save
    before_create
    after_create
    before_update
    after_update
    before_destroy
    after_destroy
  ].each do |callback|
    attr_accessor callback
    send(callback) { self.send "#{callback}=", true }
  end
end
