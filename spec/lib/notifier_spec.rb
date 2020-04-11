require 'rails_helper'

RSpec.describe Notifier, '#call' do
  subject { described_class.new(appointment) }
  let!(:appointment) { create(:appointment) }
  let(:mailer) { double }
  let(:activity) { double(id: 1) }

  before do
    allow(AppointmentMailer).to receive(:cancelled) { mailer }
    allow(AppointmentMailer).to receive(:confirmation) { mailer }
    allow(AppointmentMailer).to receive(:missed) { mailer }
    allow(AppointmentMailer).to receive(:updated) { mailer }
    allow(mailer).to receive(:deliver)
  end

  context 'when the appointment is rescheduled' do
    it 'enqueues the rescheduled notifications' do
      new_guider = create(:guider)
      appointment.update_attribute(:guider_id, new_guider.id)

      expect(AppointmentRescheduledNotificationsJob).to receive(:perform_later).with(appointment)

      subject.call
    end
  end

  context 'when the appointment is without an associated email' do
    it 'does not notify the customer' do
      expect(AppointmentMailer).not_to receive(:confirmation)

      appointment.update_attribute(:email, '')

      subject.call
    end
  end

  context 'and I update a core detail' do
    before { appointment.update_attribute(:first_name, 'Jean Ralphio') }

    it 'sends the customer a mail' do
      expect(AppointmentMailer).to receive(:updated).with(appointment)
      subject.call
    end

    it 'creates a CustomerUpdateActvity' do
      subject.call

      expect(CustomerUpdateActivity.last).to have_attributes(
        message: CustomerUpdateActivity::UPDATED_MESSAGE
      )
    end

    context 'but the appointment was in the past' do
      before { travel_to 2.weeks.from_now }
      after { travel_back }

      it 'does not send customer a mail' do
        expect(AppointmentMailer).not_to receive(:updated)
        subject.call
      end

      it 'does not create a CustomerUpdateActvity' do
        expect { subject.call }.to_not change { CustomerUpdateActivity.count }
      end
    end
  end

  context 'and I cancel the appointment' do
    before { appointment.update_attribute(:status, 'cancelled_by_pension_wise') }

    it 'sends the customer a mail' do
      expect(AppointmentMailer).to receive(:cancelled).with(appointment)
      subject.call
    end

    it 'creates a CustomerUpdateActvity' do
      subject.call

      expect(CustomerUpdateActivity.last).to have_attributes(
        message: CustomerUpdateActivity::CANCELLED_MESSAGE
      )
    end

    it 'alerts the resource managers' do
      expect(AppointmentCancelledNotificationsJob).to receive(:perform_later).with(appointment)

      subject.call
    end
  end

  context 'and I mark the appointment missed' do
    before { appointment.update_attribute(:status, 'no_show') }

    it 'sends the customer a mail' do
      expect(AppointmentMailer).to receive(:missed).with(appointment)
      subject.call
    end

    it 'creates a CustomerUpdateActvity' do
      subject.call

      expect(CustomerUpdateActivity.last).to have_attributes(
        message: CustomerUpdateActivity::MISSED_MESSAGE
      )
    end
  end
end
