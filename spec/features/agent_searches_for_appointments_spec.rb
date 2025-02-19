require 'rails_helper'

RSpec.feature 'Agent searches for appointments' do
  scenario 'TPAS users do not see `processed` filters' do
    given_the_user_is_an_agent(organisation: :tpas) do
      when_they_view_the_search
      then_they_do_not_see_the_processed_filters
    end
  end

  scenario 'Other users see `processed` filters' do
    given_the_user_is_an_agent(organisation: :cas) do
      when_they_view_the_search
      then_they_see_the_processed_filters
    end
  end

  scenario 'Searching as a TP agent' do
    given_appointments_exist_across_multiple_organisations
    given_the_user_is_an_agent(organisation: :tp) do
      when_they_search_for_nothing
      then_they_see_appointments_across_multiple_organisations
    end
  end

  scenario 'Searching as a CAS resource manager' do
    given_appointments_exist_across_multiple_organisations
    given_the_user_is_a_resource_manager(organisation: :cas) do
      when_they_search_for_nothing
      then_they_are_redirected_to_their_single_appointment_for('Becky')
    end
  end

  scenario 'Searching as a TPAS resource manager' do
    given_appointments_exist_across_multiple_organisations
    given_the_user_is_a_resource_manager(organisation: :tpas) do
      when_they_search_for_nothing
      then_they_are_redirected_to_their_single_appointment_for('George')
    end
  end

  scenario 'searches for nothing' do
    given_the_user_is_an_agent do
      and_appointments_exist
      when_they_search_for_nothing
      then_they_can_see_all_appointments
    end
  end

  scenario 'searches for a name' do
    given_the_user_is_an_agent do
      and_appointments_exist
      when_they_search_for_a_name
      then_they_see_that_appointment
    end
  end

  scenario 'searches for date range', js: true do
    given_the_user_is_an_agent do
      and_appointments_exist
      and_there_is_an_appointment_in_the_future
      when_they_search_for_a_date_range
      then_they_see_that_appointment
    end
  end

  scenario 'searches for a name with multiple results' do
    given_the_user_is_an_agent do
      and_appointments_exist_with_the_same_name
      when_they_search_for_a_name
      then_they_can_see_those_filtered_appointments_only
    end
  end

  scenario 'TP agent searching after appointment creation', js: true do
    given_the_user_is_an_agent(organisation: :tp) do
      when_they_are_directed_to_the_search_page_after_creation
      then_they_see_the_money_helper_banner
    end
  end

  scenario 'Other agent searching after appointment creation', js: true do
    given_the_user_is_an_agent(organisation: :tpas) do
      when_they_are_directed_to_the_search_page_after_creation
      then_they_do_not_see_the_money_helper_banner
    end
  end

  def when_they_are_directed_to_the_search_page_after_creation
    @page = Pages::Search.new
    @page.load(query: { created: true })
  end

  def then_they_see_the_money_helper_banner
    expect(@page).to have_money_helper_banner
  end

  def then_they_do_not_see_the_money_helper_banner
    expect(@page).to have_no_money_helper_banner
  end

  def when_they_view_the_search
    @page = Pages::Search.new.tap(&:load)
  end

  def then_they_do_not_see_the_processed_filters
    expect(@page).to have_no_processed_no
    expect(@page).to have_no_processed_yes
  end

  def then_they_see_the_processed_filters
    expect(@page).to have_processed_no
    expect(@page).to have_processed_yes
  end

  def given_appointments_exist_across_multiple_organisations
    @appointments = [
      create(:appointment, first_name: 'George', guider: create(:guider, :tpas)),
      create(:appointment, first_name: 'Daisy', guider: create(:guider, :tp)),
      create(:appointment, first_name: 'Becky', guider: create(:guider, :cas))
    ]
  end

  def then_they_see_appointments_across_multiple_organisations
    expect(@page).to have_results(count: 3)

    %w(George Daisy Becky).each { |name| expect(@page).to have_text(name) }
  end

  def then_they_are_redirected_to_their_single_appointment_for(name)
    @page = Pages::EditAppointment.new
    expect(@page).to be_displayed

    expect(@page.first_name.value).to eq(name)
  end

  def and_appointments_exist
    from = BusinessDays.from_now(3).at_midday

    @appointments = [
      create(:appointment, created_at: from + 2.seconds),
      create(:appointment, created_at: from + 1.second),
      create(:appointment, created_at: from)
    ]
  end

  def and_appointments_exist_with_the_same_name
    @appointments = [
      create(:appointment, first_name: 'Joe'),
      create(:appointment, first_name: 'Joe'),
      create(:appointment, first_name: 'Susan')
    ]
  end

  def when_they_search_for_nothing
    @page = Pages::Search.new.tap(&:load)
  end

  def then_they_can_see_all_appointments
    expected = @appointments.map { |a| "##{a.id}" }
    actual = @page.results.map(&:id).map(&:text)
    expect(actual).to eq expected
  end

  def then_they_can_see_those_filtered_appointments_only
    expected = @appointments.select { |a| a.first_name == @expected_appointment.first_name }.map(&:name).sort
    actual = @page.results.map(&:name).map(&:text).sort
    expect(actual).to eq expected
  end

  def when_they_search_for_a_name
    @page = Pages::Search.new.tap(&:load)
    @expected_appointment = @appointments.second
    @page.q.set(@expected_appointment.first_name)
    @page.search.click
  end

  def then_they_see_that_appointment
    expect(@page).to have_text(@expected_appointment.name)
  end

  def and_there_is_an_appointment_in_the_future
    @expected_appointment = create(
      :appointment,
      start_at: 30.days.from_now
    )
  end

  def when_they_search_for_a_date_range
    @page = Pages::Search.new.tap(&:load)
    start_at = I18n.l(18.days.from_now.to_date, format: :date_range_picker)
    end_at   = I18n.l(23.days.from_now.to_date, format: :date_range_picker)
    @page.execute_script("$('.t-date-range').data('daterangepicker').setStartDate('#{start_at}')")
    @page.execute_script("$('.t-date-range').data('daterangepicker').setEndDate('#{end_at}')")
    @page.search.click
  end
end
