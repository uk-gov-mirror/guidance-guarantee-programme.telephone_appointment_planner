module Pages
  class Search < Base
    set_url '/appointments/search{?query*}'

    element :q,          '.t-q'
    element :date_range, '.t-date-range'
    element :processed_no, '.t-processed-no'
    element :processed_yes, '.t-processed-yes'
    element :search,     '.t-search'
    element :rebook,     '.t-rebook'

    sections :results, '.t-result' do
      element :id, '.t-id'
      element :name, '.t-name'
    end

    elements :processed, '.t-processed'

    element :money_helper_banner, '.t-money-helper-banner'
  end
end
