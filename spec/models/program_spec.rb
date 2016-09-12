require 'rails_helper'
require Rails.root.join('spec', 'models', 'concerns', 'nameable_spec')
require Rails.root.join('spec', 'models', 'concerns', 'finance_spendable_spec')

RSpec.describe Program, type: :model do
  it_behaves_like 'nameable'
  it_behaves_like 'FinanceSpendable'
end