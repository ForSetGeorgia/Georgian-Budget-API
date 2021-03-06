require 'rails_helper'
require Rails.root.join('spec', 'validators', 'start_end_date_validator_spec')
require Rails.root.join('spec', 'models', 'concerns', 'time_periodable_spec')
require Rails.root.join('spec', 'models', 'concerns', 'amountable_spec')

RSpec.describe PlannedFinance do
  it_behaves_like 'TimePeriodable'
  it_behaves_like 'Amountable'
  include_examples 'StartEndDateValidator'

  let(:new_planned_finance) do
    FactoryGirl.build(:planned_finance)
  end

  let(:planned_finance1) do
    FactoryGirl.create(
      :planned_finance,
      start_date: Date.new(2014, 12, 1),
      end_date: Date.new(2014, 12, 31)
    )
  end

  let(:planned_finance1b) do
    FactoryGirl.create(
      :planned_finance,
      start_date: planned_finance1.time_period_obj.next.start_date,
      end_date: planned_finance1.time_period_obj.next.end_date,
      finance_plannable: planned_finance1.finance_plannable
    )
  end

  let(:planned_finance1c) do
    FactoryGirl.create(
      :planned_finance,
      start_date: planned_finance1b.time_period_obj.next.start_date,
      end_date: planned_finance1b.time_period_obj.next.end_date,
      finance_plannable: planned_finance1b.finance_plannable
    )
  end

  let(:planned_finance1d) do
    FactoryGirl.create(
      :planned_finance,
      start_date: planned_finance1c.time_period_obj.next.start_date,
      end_date: planned_finance1c.time_period_obj.next.end_date,
      finance_plannable: planned_finance1c.finance_plannable
    )
  end

  let(:planned_finance2) { FactoryGirl.create(:planned_finance) }

  it 'is valid with valid attributes' do
    expect(new_planned_finance).to be_valid
  end

  describe '#primary' do
    it 'is set to false by default' do
      planned_finance1.primary = nil
      planned_finance1.save!

      expect(planned_finance1.primary).to eq(false)
    end
  end

  describe '#official' do
    it 'is required' do
      planned_finance1.official = nil

      expect(planned_finance1.valid?).to eq(false)
      expect(planned_finance1).to have(1).error_on(:official)
    end
  end

  describe '#announce_date' do
    it 'is required' do
      planned_finance1.announce_date = nil

      expect(planned_finance1).to have(1).error_on(:announce_date)
    end

    context 'when official' do
      it 'is unique for same finance_plannable and time period' do
        planned_finance1.update_attribute(:official, true)
        planned_finance1b.official = true
        planned_finance1b.start_date = planned_finance1.start_date
        planned_finance1b.end_date = planned_finance1.end_date
        planned_finance1b.announce_date = planned_finance1.announce_date

        expect(planned_finance1b).to have(1).error_on(:announce_date)
      end
    end

    context 'when not official' do
      it 'does not have to be unique for same finance_plannable and time period' do
        planned_finance1.update_attribute(:official, true)
        planned_finance1b.official = false
        planned_finance1b.start_date = planned_finance1.start_date
        planned_finance1b.end_date = planned_finance1.end_date
        planned_finance1b.announce_date = planned_finance1.announce_date

        expect(planned_finance1b).to have(0).error_on(:announce_date)
      end
    end
  end

  describe '#finance_plannable' do
    it 'is required' do
      new_planned_finance.finance_plannable = nil

      expect(new_planned_finance).to have(1).error_on(:finance_plannable)
    end
  end

  describe '==' do
    context 'when two planned finances' do
      before :each do
        planned_finance1b.update_attributes(
          finance_plannable: planned_finance1.finance_plannable,
          start_date: planned_finance1.start_date,
          end_date: planned_finance1.end_date,
          # announce date must be different, otherwise validation won't pass
          announce_date: planned_finance1.announce_date + 1,
          amount: planned_finance1.amount
        )
      end

      context 'have different finance plannable' do
        it 'returns false' do
          planned_finance1b.update_attributes(
            announce_date: planned_finance1.announce_date,
            finance_plannable: FactoryGirl.create(:program)
          )

          planned_finance1b.reload

          expect(planned_finance1 == planned_finance1b).to eq(false)
        end
      end

      context 'have different start date' do
        it 'returns false' do
          planned_finance1b.update_attributes(
            announce_date: planned_finance1.announce_date,
            time_period_obj: planned_finance1.time_period_obj.next
          )

          planned_finance1b.reload

          expect(planned_finance1 == planned_finance1b).to eq(false)
        end
      end

      context 'have different announce date' do
        context 'and amounts are the same' do
          it 'returns true' do
            planned_finance1b.reload

            expect(planned_finance1 == planned_finance1b).to eq(true)
          end
        end

        context 'and amounts are different' do
          it 'returns false' do
            planned_finance1b.update_attributes(
              amount: planned_finance1.amount + 1
            )

            planned_finance1b.reload

            expect(planned_finance1 == planned_finance1b).to eq(false)
          end
        end
      end
    end
  end

  describe '.total' do
    it 'gets the sum of the planned finance amounts' do
      planned_finance1.save!
      planned_finance1b.save!

      expect(PlannedFinance.all.total).to eq(
        planned_finance1.amount + planned_finance1b.amount
      )
    end
  end

  describe '.prefer_official' do
    subject { PlannedFinance.prefer_official }

    let!(:unofficial_tp1) do
      FactoryGirl.create(:planned_finance, official: false)
    end

    let!(:official_tp1) do
      FactoryGirl.create(:planned_finance,
        finance_plannable: unofficial_tp1.finance_plannable,
        time_period_obj: unofficial_tp1.time_period_obj,
        announce_date: unofficial_tp1.announce_date,
        official: true)
    end

    let!(:unofficial_tp2) do
      FactoryGirl.create(:planned_finance,
        finance_plannable: unofficial_tp1.finance_plannable,
        official: false)
    end

    it { is_expected.to_not include(unofficial_tp1) }
    it { is_expected.to include(official_tp1) }
    it { is_expected.to include(unofficial_tp2) }
  end
end
