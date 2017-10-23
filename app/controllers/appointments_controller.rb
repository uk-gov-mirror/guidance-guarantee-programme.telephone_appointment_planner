# rubocop:disable Metrics/ClassLength
class AppointmentsController < ApplicationController
  before_action :authenticate_user!
  store_previous_page_on :search

  def batch_update
    BatchAppointmentUpdate.new(params[:changes]).call
    head :ok
  end

  def index
    @appointments = appointment_scope.where(start_at: date_range_params)

    render json: @appointments if stale?(@appointments)
  end

  def edit
    @appointment = Appointment.find(params[:id])
  end

  def reschedule
    @appointment = Appointment.find(params[:appointment_id])
    @appointment.start_at = nil
    @appointment.end_at = nil
  end

  def update_reschedule
    @appointment = Appointment.find(params[:appointment_id])
    @appointment.assign_attributes(update_reschedule_params)
    @appointment.assign_to_guider
    if @appointment.save
      Notifier.new(@appointment).call
      redirect_to edit_appointment_path(@appointment), success: 'Appointment has been rescheduled'
    else
      render :reschedule
    end
  end

  def update
    @appointment = Appointment.find(params[:id])
    if @appointment.update_attributes(update_params)
      Notifier.new(@appointment).call
      redirect_to edit_appointment_path(@appointment), success: 'Appointment has been modified'
    else
      render :edit
    end
  end

  def new
    @appointment = Appointment.copy_or_new_by(params[:copy_from])

    if @appointment
      render :new
    else
      redirect_back warning: I18n.t('appointments.rebooking'), fallback_location: search_appointments_path
    end
  end

  def preview
    @appointment = Appointment.new(create_params.merge(agent: current_user))
    @appointment.assign_to_guider
    if @appointment.valid?
      render :preview
    else
      render :new
    end
  end

  def create
    @appointment = Appointment.new(create_params.merge(agent: current_user))
    @appointment.assign_to_guider

    if creating? && @appointment.save
      CustomerUpdateJob.perform_later(@appointment, CustomerUpdateActivity::CONFIRMED_MESSAGE)
      redirect_to(search_appointments_path, success: 'Appointment has been created')
    else
      render :new
    end
  end

  def search
    @search = Search.new(
      search_params[:q],
      search_params[:date_range]
    )

    return redirect_on_exact_match(@search.results.first) if @search.results.one?

    @results = @search.results.page(params[:page])
  end

  private

  def redirect_on_exact_match(result)
    redirect_to(edit_appointment_path(result))
  end

  def appointment_scope
    if scoped_to_me?
      current_user.appointments
    else
      Appointment.unscoped
    end
  end

  def scoped_to_me?
    params.key?(:mine)
  end

  def search_params
    params.fetch(:search, {}).permit(:q, :date_range)
  end

  def date_range_params
    starts = params[:start].to_date.beginning_of_day
    ends   = params[:end].to_date.beginning_of_day

    starts..ends
  end

  # rubocop:disable Metrics/MethodLength
  def updateable_params
    [
      :first_name,
      :last_name,
      :email,
      :phone,
      :mobile,
      :date_of_birth,
      :memorable_word,
      :notes,
      :opt_out_of_market_research,
      :status,
      :type_of_appointment,
      :where_you_heard
    ]
  end
  # rubocop:enable Metrics/MethodLength

  def update_params
    params.require(:appointment).permit(updateable_params)
  end

  def create_params
    params.require(:appointment).permit(
      updateable_params.concat(%i(start_at end_at rebooked_from_id))
    )
  end

  def update_reschedule_params
    params.require(:appointment).permit(:start_at, :end_at)
  end

  def creating?
    params[:edit_appointment].nil?
  end
end
