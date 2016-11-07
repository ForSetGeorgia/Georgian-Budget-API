module TimePeriodable
  extend ActiveSupport::Concern

  included do
    validates_with StartEndDateValidator
    validate :validate_time_period_type_is_recognizable

    before_save :set_time_period_type
  end

  module ClassMethods
    def with_time_period(time_period)
      where(start_date: time_period.start_date, end_date: time_period.end_date)
    end

    def monthly
      where(time_period_type: 'month')
    end

    def quarterly
      where(time_period_type: 'quarter')
    end

    def yearly
      where(time_period_type: 'year')
    end
  end

  def time_period_class
    return Month if time_period_type == 'month'
    return Quarter if time_period_type == 'quarter'
    return Year if time_period_type == 'year'

    nil
  end

  def time_period
    time_period_class.for_date(start_date)
  end

  def time_period=(time_period)
    self.start_date = time_period.start_date
    self.end_date = time_period.end_date
  end

  private

  def validate_time_period_type_is_recognizable
    return if start_date.blank?
    return if end_date.blank?

    if get_time_period_type_from_dates.nil?
      errors.add(:time_period_type, "of start and end date is unrecognized")
    end
  end

  def set_time_period_type
    self[:time_period_type] = get_time_period_type_from_dates
  end

  def get_time_period_type_from_dates
    return 'month' if Month.dates_valid?(start_date, end_date)
    return 'quarter' if Quarter.dates_valid?(start_date, end_date)
    return 'year' if Year.dates_valid?(start_date, end_date)

    nil
  end
end