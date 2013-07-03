require 'spec_helper'

describe ElasticRecord::Base do

  describe '.create' do
    subject { TestRecord.create params }

    context 'a valid record' do
      let(:params) { { subject: 'Hello, World!' } }

      it { should be_valid }
      it { should be_persisted }
    end

    context 'an invalid record' do
      let(:params) { nil }

      it { should be_invalid }
      it { should be_new_record }
      its(:errors) { should be_present }
    end
  end

  describe '.create!' do
    context 'an invalid record' do
      it 'raises ElasticRecord::RecordInvalid' do
        expect { TestRecord.create! }.to raise_error(
          ElasticRecord::RecordInvalid
        )
      end
    end
  end

  describe '.update_mapping' do

    context 'without an existing mapping' do
      before { TestRecord.with_index { |index| index.delete } }

      it 'creates mapping' do
        TestRecord.with_index { |index| index.exists?.should eq false }
        TestRecord.update_mapping.ok.should eq true
      end
    end

    context 'with an existing mapping' do
      it 'updates mapping' do
        TestRecord.with_index { |index| index.exists?.should eq true }
        TestRecord.update_mapping.ok.should eq true
      end
    end
  end

  describe 'a date-type property' do
    it 'typecasts' do
      timestamp = Time.now.iso8601
      record = TestRecord.new publish_at: timestamp
      record.publish_at.should eq Time.iso8601 timestamp
    end
  end

  describe '#initialize' do
    subject { TestRecord.new params }
    let(:params) { {} }

    it { should be_new_record }
    it { should_not be_destroyed }
    its(:attributes) { should be_empty }
    its(:meta) { should be_empty }

    context 'with after_initialize callbacks' do
      it 'runs callbacks' do
        subject.after_initialize.should eq true
      end
    end

    context 'with params' do
      let(:params) { { subject: 'Hello, World' } }

      its(:attributes) { should_not be_empty }
    end
  end

  describe '#attributes=' do
    context 'with writer methods defined' do
      it 'calls writer methods' do
        record = TestRecord.new
        record.should receive :subject=
        record.attributes = { subject: 'Hello, World' }
      end
    end

    context 'without writer methods defined' do
      it 'calls write_attribute' do
        record = TestRecord.new
        record.should receive :write_attribute
        record.attributes = { attribute: 'Written' }
      end
    end
  end

  describe '#read_attribute' do
    it 'returns attribute' do
      subject = 'Hello, World'
      record = TestRecord.new subject: subject
      record.read_attribute(:subject).should eq subject
    end
  end

  describe '#write_attribute' do
    context 'with a new value' do
      subject { TestRecord.new }
      let(:new_value) { 'new value' }

      before { subject.write_attribute :subject, new_value }

      its(:changed_attributes) { should include 'subject' }
      its(:subject) { should eq new_value }
    end

    context 'with the same value' do
      its(:changed_attributes) { should be_empty }
    end
  end

  describe '#save' do
    let(:record) { TestRecord.new params }
    subject(:save) { record.save }

    context 'a valid record' do
      let(:params) { { subject: 'Hello, World' } }

      it 'saves record and returns true' do
        save.should eq true
        record.should be_persisted
      end

      it 'runs save callbacks' do
        save
        record.before_save.should eq true
        record.after_save.should eq true
      end

      context 'being created' do
        it 'runs create callbacks' do
          save
          record.before_create.should eq true
          record.after_create.should eq true
        end
      end

      context 'being updated' do
        let(:record) { TestRecord.create! subject: 'Hi, World' }

        it 'runs update callbacks' do
          record.subject = 'Hello, World'
          save
          record.before_update.should eq true
          record.after_update.should eq true
        end
      end
    end

    context 'an invalid record' do
      let(:params) { nil }

      it 'applies errors and returns false' do
        save.should eq false
      end
    end
  end

  describe '#save!' do
    context 'an invalid record' do
      it 'raises ElasticRecord::RecordInvalid' do
        record = TestRecord.new
        expect { record.save! }.to raise_error ElasticRecord::RecordInvalid
      end
    end
  end

  describe '#update_attributes' do
    subject(:record) { TestRecord.create! subject: 'Hello, World' }
    let(:update_attributes) { subject.update_attributes params }

    context 'a valid record' do
      let(:params) { { subject: 'Goodbye, Cruel World' } }

      it 'updates record and returns true' do
        update_attributes.should eq true
      end
    end

    context 'an invalid record' do
      let(:params) { { subject: nil } }

      it 'applies errors and returns false' do
        update_attributes.should eq false
      end
    end
  end

  describe '#update_attributes!' do
    context 'an invalid record' do
      it 'raises ElasticRecord::RecordInvalid' do
        record = TestRecord.create! subject: 'Hello, World'
        expect { record.update_attributes! subject: nil }.to raise_error(
          ElasticRecord::RecordInvalid
        )
      end
    end
  end

  describe '#destroy' do
    context 'a new record' do
      it 'returns false' do
        TestRecord.new.destroy.should eq false
      end
    end

    context 'an existing record' do
      subject(:record) { TestRecord.create! subject: 'Hello, World' }
      let(:destroy) { record.destroy }

      it 'removes the record and returns true' do
        destroy.should eq true
        expect { TestRecord.find record.id }.to raise_error(
          Stretcher::RequestError::NotFound
        )
      end

      it 'runs callbacks' do
        destroy
        record.before_destroy.should eq true
        record.after_destroy.should eq true
      end

      context 'after destroy' do
        before { destroy }

        it 'returns false' do
          record.destroy.should eq false
        end
      end
    end
  end

end
