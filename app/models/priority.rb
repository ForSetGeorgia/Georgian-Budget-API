class Priority < ApplicationRecord
  include Nameable
  include FinanceSpendable
  include FinancePlannable
  include PermaIdable

  has_many :programs
  has_many :spending_agencies,
           -> { distinct },
           through: :programs

  has_many :connections,
           class_name: 'PriorityConnection'

  def type
    self.class.to_s.underscore
  end
end
