=begin
The Georgian government changes the planned finance sometimes for a
specific budget item (program, priority or agency) and period. For example,
the Ministry of Education may say in January that they plan to spend
1,000,000 lari in the first quarter, and then change that plan
in February to 2,000,000 lari. In the following case, this agency record
will have two planned finances:

Announce date: January 1
Start date: January 1, 2015
End date: March 31, 2015
Amount: 1,000,000

Announce date: February 1
Start date: January 1, 2015
End date: March 31, 2015
Amount: 2,000,000

In this example, the second plan will be marked with the flag
most_recently_announced.

=end
module FinancePlannable
  extend ActiveSupport::Concern

  included do
    has_many :all_planned_finances,
             -> { order('planned_finances.start_date').order('planned_finances.announce_date') },
             as: :finance_plannable,
             class_name: 'PlannedFinance',
             dependent: :destroy

    has_many :planned_finances,
             -> { primary.order('planned_finances.start_date') },
             as: :finance_plannable

    has_many :yearly_planned_finances,
             -> { primary.order('planned_finances.start_date').where(time_period_type: 'year') },
             as: :finance_plannable,
             class_name: 'PlannedFinance'
  end

  def add_planned_finance(params, args = {})
    transaction do
      params[:finance_plannable] = self
      new_planned_finance = PlannedFinance.create!(params)

      planned_finance = update_with_new_planned_finance(new_planned_finance, args)

      return planned_finance if args[:return_finance]

      self
    end
  end

  def take_planned_finance(new_planned_finance, args = {})
    transaction do
      new_planned_finance.update_attributes!(finance_plannable: self)

      planned_finance = update_with_new_planned_finance(new_planned_finance, args)

      return planned_finance if args[:return_finance]

      self
    end
  end

  private

  def update_with_new_planned_finance(new_planned_finance, args = {})
    planned_finance = merge_new_planned_finance(new_planned_finance)
    update_most_recently_announced_with(planned_finance)
    DatesUpdater.new(self, planned_finance).update
    FinanceCategorizer.new(planned_finance).set_primary

    return planned_finance
  end

  # returns the newly merged finance
  def merge_new_planned_finance(new_planned_finance)
    time_period_siblings = planned_finances_with_time_period(
      new_planned_finance.start_date,
      new_planned_finance.end_date
    )

    return new_planned_finance if time_period_siblings.count == 1

    new_planned_finance_index = time_period_siblings.to_a.index do |sibling|
      sibling.id == new_planned_finance.id
    end

    ### destroy subsequent announce date if it has the same amount
    next_sibling = time_period_siblings[new_planned_finance_index + 1]

    if next_sibling.present? && new_planned_finance == next_sibling
      next_sibling.destroy
    end

    return new_planned_finance if new_planned_finance_index == 0

    ### destroy previous announce date if it has the same amount
    previous_sibling = time_period_siblings[new_planned_finance_index - 1]

    if previous_sibling.present? && previous_sibling == new_planned_finance
      new_planned_finance.destroy
      return previous_sibling
    end

    return new_planned_finance
  end

  def update_most_recently_announced_with(new_planned_finance)
    time_period_siblings = planned_finances_with_time_period(
      new_planned_finance.start_date,
      new_planned_finance.end_date
    )

    # if there is only one, then it should be most_recently_announced
    if time_period_siblings.length == 1
      new_planned_finance.update_column(:most_recently_announced, true)
      return true
    end

    # if there are more than one, then set most_recently_announced to false
    # for all of them, and then set most_recently_announced to true
    # for the one with the latest announce_date
    time_period_siblings.update_all(
      most_recently_announced: false
    )

    time_period_siblings
    .order(:announce_date)
    .last
    .update_column(:most_recently_announced, true)

    return true
  end

  def planned_finances_with_time_period(start_date, end_date)
    all_planned_finances
    .where(start_date: start_date, end_date: end_date)
    .order(:announce_date)
  end
end
