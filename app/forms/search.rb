class Search
  include ActiveModel::Model

  attr_reader :q
  attr_reader :date_range

  def initialize(q, date_range)
    @q = q
    @date_range = date_range
  end

  def results
    range = date_range
            .to_s
            .split(' - ')
            .map { |d| Time.zone.strptime(d, I18n.t('date.formats.date_range_picker')) }
    Appointment.full_search(
      q,
      range.first.try(:beginning_of_day),
      range.last.try(:end_of_day)
    )
  end
end
