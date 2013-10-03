require 'spec_helper'

describe ElasticRecord::Mapping do

  describe '.index_name' do

    it 'returns the index name when no args are passed' do
      TestRecord.index_name.should eq 'test_records'
    end

    context 'args' do

      let!(:original_name) { TestRecord.index_name }
      after { TestRecord.index_name original_name }

      context 'with index name' do

        let(:index_name) { 'my_index' }

        it 'assigns the index name when one is passed' do
          TestRecord.index_name index_name
          TestRecord.index_name.should eq index_name
        end

      end

      context 'with wildcard' do

        let(:index_name) { 'my_index_*' }
        let(:options) { { wildcard: wildcard } }
        let(:timestamp) { Time.now.utc }
        let :wildcard do
          -> record do
            (record ? record._timestamp : timestamp).strftime '%Y_%m'
          end
        end

        before do
          TestRecord.index_name index_name, options
        end

        it 'returns a current index' do
          current_index_name = timestamp.strftime 'my_index_%Y_%m'
          TestRecord.current_index_name.should eq current_index_name
        end

        it "returns a record's index" do
          months_ago = timestamp - (60 * 60 * 24 * 31 * 2) # 2 months
          record = TestRecord.create(
            subject: 'Hello, World!', _timestamp: months_ago
          )
          old_index_name = months_ago.strftime 'my_index_%Y_%m'
          TestRecord.current_index_name(record).should eq old_index_name
        end

      end

    end

  end

end
