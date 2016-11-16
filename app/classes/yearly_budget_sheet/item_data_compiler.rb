class YearlyBudgetSheet::ItemDataCompiler
  def initialize(yearly_sheet_item, args)
    @yearly_sheet_item = yearly_sheet_item
    @year = args[:year]
  end

  def code_number
    yearly_sheet_item.code_number
  end

  def code_data
    {
      start_date: year.start_date,
      number: code_number
    }
  end

  def name_data
    {
      start_date: year.start_date,
      text_en: nil,
      text_ka: yearly_sheet_item.name_ka
    }
  end

  def spent_finance_data
    return nil if yearly_sheet_item.two_years_earlier_spent_amount.blank?

    two_years_ago = year.previous.previous

    {
      start_date: two_years_ago.start_date,
      end_date: two_years_ago.end_date,
      amount: yearly_sheet_item.two_years_earlier_spent_amount
    }
  end

  def planned_finance_data
    finances = []

    if yearly_sheet_item.previous_year_plan_amount.present?
      previous_year = year.previous

      finances << {
        start_date: previous_year.start_date,
        end_date: previous_year.end_date,
        announce_date: year.start_date,
        amount: yearly_sheet_item.previous_year_plan_amount
      }
    end

    if yearly_sheet_item.current_year_plan_amount.present?
      finances << {
        start_date: year.start_date,
        end_date: year.end_date,
        announce_date: year.start_date,
        amount: yearly_sheet_item.current_year_plan_amount
      }
    end

    finances
  end

  attr_reader :yearly_sheet_item,
              :year
end
