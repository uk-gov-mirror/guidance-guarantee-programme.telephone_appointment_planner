require 'rails_helper'

RSpec.describe SmsCancellation do
  include ActiveJob::TestHelper

  subject { described_class.new(source_number: '07715 930 455', message: 'Cancel.') }

  describe 'validation' do
    it 'is valid with valid attributes' do
      expect(subject).to be_valid
    end

    it 'requires the `source_number`' do
      subject.source_number = ''

      expect(subject).to be_invalid
    end

    it 'requires the correct `message` for cancellation' do
      subject.message = 'Please cancel my appointment.'

      expect(subject).to be_invalid
    end
  end

  describe '#call' do
    let(:appointment) { create(:appointment, mobile: '07715930455', status: :complete) }

    context 'when the underlying appointment is not pending' do
      it 'does not attempt to cancel and notifies the customer' do
        subject.call

        expect(appointment.reload).to be_complete

        assert_enqueued_jobs(1, only: SmsCancellationFailureJob)
      end
    end
  end
end
