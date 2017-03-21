require 'rails_helper'
require Rails.root.join('lib', 'budget_uploader', 'budget_files').to_s

RSpec.describe 'BudgetFiles' do
  describe '#upload' do
    context 'with yearly spreadsheets' do
      before :example do
        I18n.locale = 'ka'
      end

      before :context do
        Program.create
        .add_name(FactoryGirl.attributes_for(:name,
          text_ka: 'მეცნიერებისა და სამეცნიერო კვლევების ხელშეწყობა'))
        .add_code(FactoryGirl.attributes_for(:code,
          number: '32 04 02',
          start_date: Date.new(2015, 1, 1)))
        .reload
        .save_perma_id
        .add_code(FactoryGirl.attributes_for(:code,
          number: '32 05',
          start_date: Date.new(2016, 1, 1)))
        .reload
        .save_perma_id

        Program.create
        .add_name(FactoryGirl.attributes_for(:name,
          text_ka: 'სახელმწიფო სასწავლო, სამაგისტრო გრანტები და ახალგაზრდების წახალისება'))
        .add_code(FactoryGirl.attributes_for(:code,
          number: '32 04 03',
          start_date: Date.new(2015, 1, 1)))
        .reload
        .save_perma_id
        .add_code(FactoryGirl.attributes_for(:code,
          number: '32 04 02',
          start_date: Date.new(2016, 1, 1)))
        .reload
        .save_perma_id

        yearly_files_dir = BudgetFiles.yearly_spreadsheet_dir

        BudgetFiles.new(
          yearly_paths: [
            yearly_files_dir.join('yearly_spreadsheet-2015-original-formatted.xlsx').to_s,
            yearly_files_dir.join('yearly_spreadsheet-2016-original-formatted.xlsx').to_s
          ]
        ).upload
      end

      after :context do
        Deleter.delete_all_budget_data
      end

      describe 'total:' do
        let(:budget_item) do
          BudgetItem.find(
            code: '00',
            name: 'მთლიანი სახელმწიფო ბიუჯეტი'
          )
        end

        it 'saved the 2013 spent amount' do
          finance = budget_item.spent_finances
          .with_time_period(Year.new(2013))
          .first

          expect(finance.amount.to_f).to eq(8104217600)
          expect(finance.official).to eq(true)
        end

        it 'saved the 2014 plan announced in 2015' do
          finance = budget_item.planned_finances
          .with_time_period(Year.new(2014))
          .where(announce_date: Date.new(2015, 1, 1))
          .first

          expect(finance.amount.to_f).to eq(9080000000)
          expect(finance.official).to eq(true)
        end

        it 'saved the 2015 plan announced in 2015' do
          finance = budget_item.all_planned_finances
          .with_time_period(Year.new(2015))
          .where(announce_date: Date.new(2015, 1, 1))
          .first

          expect(finance.amount.to_f).to eq(9575000000)
          expect(finance.official).to eq(true)
        end

        it 'saved the 2014 spent amount' do
          finance = budget_item.spent_finances
          .with_time_period(Year.new(2014))
          .first

          expect(finance.amount.to_f).to eq(9009812200)
          expect(finance.official).to eq(true)
        end

        it 'saved the 2015 plan announced in 2016' do
          finance = budget_item.planned_finances
          .with_time_period(Year.new(2015))
          .where(announce_date: Date.new(2016, 1, 1))
          .first

          expect(finance.amount.to_f).to eq(9620000000)
          expect(finance.official).to eq(true)
        end

        it 'saved the 2016 plan announced in 2016' do
          finance = budget_item.planned_finances
          .with_time_period(Year.new(2016))
          .where(announce_date: Date.new(2016, 1, 1))
          .first

          expect(finance.amount.to_f).to eq(10145000000)
          expect(finance.official).to eq(true)
        end
      end

      describe '24 00 agency:' do
        let(:budget_item) do
          BudgetItem.find(
            code: '24 00',
            name: 'საქართველოს ეკონომიკისა და მდგრადი განვითარების სამინისტრო'
          )
        end

        it 'saved the 2013 spent amount' do
          finance = budget_item.spent_finances
          .with_time_period(Year.new(2013))
          .first

          expect(finance.amount.to_f).to eq(123541400)
        end

        it 'saved the 2014 plan announced in 2015' do
          finance = budget_item.planned_finances
          .with_time_period(Year.new(2014))
          .where(announce_date: Date.new(2015, 1, 1))
          .first

          expect(finance.amount.to_f).to eq(131091000)
        end

        it 'saved the 2015 plan announced in 2015' do
          finance = budget_item.all_planned_finances
          .with_time_period(Year.new(2015))
          .where(announce_date: Date.new(2015, 1, 1))
          .first

          expect(finance.amount.to_f).to eq(120000000)
        end

        it 'saved the 2014 spent amount' do
          finance = budget_item.spent_finances
          .with_time_period(Year.new(2014))
          .first

          expect(finance.amount.to_f).to eq(88395600)
        end

        it 'saved the 2015 plan announced in 2016' do
          finance = budget_item.planned_finances
          .with_time_period(Year.new(2015))
          .where(announce_date: Date.new(2016, 1, 1))
          .first

          expect(finance.amount.to_f).to eq(85368100)
        end

        it 'saved the 2016 plan announced in 2016' do
          finance = budget_item.planned_finances
          .with_time_period(Year.new(2016))
          .where(announce_date: Date.new(2016, 1, 1))
          .first

          expect(finance.amount.to_f).to eq(95100000)
        end
      end

      describe '32 04 02 მეცნიერებისა და სამეცნიერო კვლევების ხელშეწყობა:' do
        let(:budget_item) do
          BudgetItem.find(
            code: '32 04 02',
            name: 'მეცნიერებისა და სამეცნიერო კვლევების ხელშეწყობა'
          )
        end

        it 'saved the 2013 spent amount' do
          finance = budget_item.spent_finances
          .with_time_period(Year.new(2013))
          .first

          expect(finance.amount.to_f).to eq(27115100)
        end

        it 'saved the 2014 plan announced in 2015' do
          finance = budget_item.planned_finances
          .with_time_period(Year.new(2014))
          .where(announce_date: Date.new(2015, 1, 1))
          .first

          expect(finance.amount.to_f).to eq(49707000)
        end

        it 'saved the 2015 plan announced in 2015' do
          finance = budget_item.all_planned_finances
          .with_time_period(Year.new(2015))
          .where(announce_date: Date.new(2015, 1, 1))
          .first

          expect(finance.amount.to_f).to eq(60500000)
        end

        it 'saved the 2014 spent amount' do
          finance = budget_item.spent_finances
          .with_time_period(Year.new(2014))
          .first

          expect(finance.amount.to_f).to eq(32410100)
        end

        it 'saved the 2015 plan announced in 2016' do
          finance = budget_item.planned_finances
          .with_time_period(Year.new(2015))
          .where(announce_date: Date.new(2016, 1, 1))
          .first

          expect(finance.amount.to_f).to eq(60417400)
        end

        it 'saved the 2016 plan announced in 2016' do
          finance = budget_item.planned_finances
          .with_time_period(Year.new(2016))
          .where(announce_date: Date.new(2016, 1, 1))
          .first

          expect(finance.amount.to_f).to eq(66747000)
        end
      end

      describe '32 04 02 სახელმწიფო სასწავლო, სამაგისტრო:' do
        let(:budget_item) do
          BudgetItem.find(
            code: '32 04 02',
            name: 'სახელმწიფო სასწავლო, სამაგისტრო გრანტები და ახალგაზრდების წახალისება'
          )
        end

        it 'saved the 2013 spent amount' do
          finance = budget_item.spent_finances
          .with_time_period(Year.new(2013))
          .first

          expect(finance.amount.to_f).to eq(59208700)
        end

        it 'saved the 2014 plan announced in 2015' do
          finance = budget_item.planned_finances
          .with_time_period(Year.new(2014))
          .where(announce_date: Date.new(2015, 1, 1))
          .first

          expect(finance.amount.to_f).to eq(76440000)
        end

        it 'saved the 2015 plan announced in 2015' do
          finance = budget_item.planned_finances
          .with_time_period(Year.new(2015))
          .where(announce_date: Date.new(2015, 1, 1))
          .first

          expect(finance.amount.to_f).to eq(82663000)
        end

        it 'saved the 2014 spent amount' do
          finance = budget_item.spent_finances
          .with_time_period(Year.new(2014))
          .first

          expect(finance.amount.to_f).to eq(74918700)
        end

        it 'saved the 2016 plan announced in 2016' do
          finance = budget_item.planned_finances
          .with_time_period(Year.new(2016))
          .where(announce_date: Date.new(2016, 1, 1))
          .first

          expect(finance.amount.to_f).to eq(89611000)
        end
      end

      describe '60 00 ა(ა)იპ – რიჩარდ გ. ლუგარის საზოგადოებრივი ჯანმრთელობის კვლევითი ცენტრი' do
        let(:budget_item) do
          BudgetItem.find(
            code: '60 00',
            name: 'ა(ა)იპ – რიჩარდ გ. ლუგარის საზოგადოებრივი ჯანმრთელობის კვლევითი ცენტრი'
          )
        end

        it 'saved the 2013 spent amount' do
          finance = budget_item.spent_finances
          .with_time_period(Year.new(2013))
          .first

          expect(finance.amount.to_f).to eq(550700)
        end

        it 'did not save the 2014 planned amount' do
          finance = budget_item.planned_finances
          .with_time_period(Year.new(2014))
          .first

          expect(finance).to eq(nil)
        end

        it 'did not save the 2015 planned amount' do
          finance = budget_item.planned_finances
          .with_time_period(Year.new(2015))
          .first

          expect(finance).to eq(nil)
        end

      end

      describe '58 10 05 - განახლებადი ენერგიის პროგრამა II (KfW)' do
        let(:budget_item) do
          BudgetItem.find(
            code: '58 10 05',
            name: 'განახლებადი ენერგიის პროგრამა II (KfW)'
          )
        end

        it 'did not save the 2013 spent amount' do
          finance = budget_item.spent_finances
          .with_time_period(Year.new(2013))
          .first

          expect(finance).to eq(nil)
        end

        it 'did not save the 2014 planned amount' do
          finance = budget_item.planned_finances
          .with_time_period(Year.new(2014)).first

          expect(finance).to eq(nil)
        end

        it 'saved the 2015 planned amount' do
          finance = budget_item.planned_finances
          .with_time_period(Year.new(2015)).first

          expect(finance.amount.to_f).to eq(200000)
        end

      end


    end
  end
end
