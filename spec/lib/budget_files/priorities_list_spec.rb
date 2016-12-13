require 'rails_helper'
require Rails.root.join('lib', 'budget_uploader', 'budget_files').to_s

RSpec.describe 'BudgetFiles' do
  describe '#upload' do
    before :example do
      I18n.locale = 'ka'
    end

    context 'with priorities list and priority associations list' do
      # add some finances to allow basic testing of functionality
      # that saves priority finances from directly connected items

      agency45_00 = create(:spending_agency)
      .add_code(attributes_for(:code, number: '45 00'))
      .add_name(attributes_for(:name, text_ka: 'საქართველოს საპატრიარქო'))
      .add_spent_finance(attributes_for(:spent_finance,
        time_period_obj: Year.new(2013)))
      .add_planned_finance(attributes_for(:planned_finance,
        time_period_obj: Year.new(2014)))

      create(:program)
      .add_code(attributes_for(:code, number: '45 01'))
      .add_name(attributes_for(:name, text_ka: 'სასულიერო განათლების ხელშეწყობის გრანტი'))
      .add_spent_finance(attributes_for(:spent_finance,
        time_period_obj: Year.new(2013)))
      .add_planned_finance(attributes_for(:planned_finance,
        time_period_obj: Year.new(2014)))

      create(:program)
      .add_code(attributes_for(:code, number: '45 02'))
      .add_name(attributes_for(:name, text_ka: 'საქართველოს საპატრიარქოს წმინდა სიმონ კანანელის სახელობის სასულიერო სწავლების ცენტრისათვის გადასაცემი გრანტი'))
      .add_spent_finance(attributes_for(:spent_finance,
        time_period_obj: Year.new(2013)))
      .add_planned_finance(attributes_for(:planned_finance,
        time_period_obj: Year.new(2014)))

      before :context do
        BudgetFiles.new(
          priorities_list: BudgetFiles.priorities_list,
          priority_associations_list: BudgetFiles.priority_associations_list
        ).upload
      end

      after :context do
        Deleter.delete_all
      end

      let(:social_welfare_priority) do
        BudgetItem.find(name: 'ხელმისაწვდომი, ხარისხიანი ჯანმრთელობის დაცვა და სოციალური უზრუნველყოფა')
      end

      let(:economic_stability_priority) do
        BudgetItem.find(name: 'მაკროეკონომიკური სტაბილურობა და საინვესტიციო გარემოს გაუმჯობესება')
      end

      let(:education_priority) do
        BudgetItem.find(name: 'განათლება, მეცნიერება და პროფესიული მომზადება')
      end

      let(:defense_priority) do
        BudgetItem.find(name: 'თავდაცვა, საზოგადოებრივი წესრიგი და უსაფრთხოება')
      end

      let(:culture_priority) do
        BudgetItem.find(
          name: 'კულტურა, რელიგია, ახალგაზრდობის ხელშეწყობა და სპორტი')
      end

      it 'creates economic stability priority' do
        expect(economic_stability_priority).to_not eq(nil)

        expect(economic_stability_priority.recent_name_object.start_date)
        .to eq(Date.new(2012, 1, 1))
      end

      it 'creates perma_id for economic stability priority' do
        expect(economic_stability_priority.perma_id).to_not eq(nil)
      end

      it 'creates education priority' do
        expect(education_priority).to_not eq(nil)

        expect(education_priority.recent_name_object.start_date)
        .to eq(Date.new(2012, 1, 1))
      end

      it 'creates perma_id for education priority' do
        expect(education_priority.perma_id).to_not eq(nil)
      end

      it 'makes correct number of direct connections to welfare priority' do
        expect(social_welfare_priority.connections.direct.length).to eq(42)
      end

      it 'makes correct number of direct connections to welfare priority in 2012' do
        expect(
          social_welfare_priority
          .connections
          .direct
          .where(Year.new(2012).to_hash)
          .length
        ).to eq(8)
      end

      it 'makes correct number of connections to welfare priority' do
        expect(social_welfare_priority.connections.length).to eq(42)
      end

      it 'makes correct number of direct connections to defense priority' do
        expect(defense_priority.connections.direct.length).to eq(79)
      end

      it 'makes correct number of connections to defense priority' do
        expect(defense_priority.connections.length).to eq(79)
      end

      it 'saves spent amount for culture priority in 2013 from 45 00 agency' do
        expect(culture_priority.spent_finances
          .with_time_period(Year.new(2013).first.amount))
        .to eq(agency45_00.spent_finances
          .with_time_period(Year.new(2013).first.amount))
      end

      it 'saves plan amount for culture priority in 2014 from 45 00 child programs' do
        child_programs = Program.where(code: ['45 01', '45 02'])

        expect(culture_priority.planned_finances
          .with_time_period(Year.new(2014).first.amount))
        .to eq(child_programs.planned_finances
          .with_time_period(Year.new(2014).pluck(:amount).sum))
      end

      # it 'assigns parliament no direct priority connections' do
      #   parliament = BudgetItem.find(
      #     code: '01 00',
      #     name: 'საქართველოს პარლამენტი და მასთან არსებული ორგანიზაციები'
      #   )
      #
      #   expect(audit_regulation_program.direct_priorities).to be_empty
      # end
      #
      # it 'assigns audit regulation program to economic stability priority in 2012' do
      #   audit_regulation_program = BudgetItem.find(code: '01 02', name: 'აუდიტორული საქმიანობის სახელმწიფო რეგულირება')
      #
      #   expect(audit_regulation_program.direct_priorities_on_date(Date.new(2012, 1, 1)))
      #   .to contain_exactly(economic_stability_priority)
      #
      #   expect(patriarch_agency.direct_priorities_on_date(Date.new(2013, 1, 1)))
      #   .to be_empty
      # end
      #
      # it 'assigns priority to library program' do
      #   library_program = BudgetItem.find(code: '01 02', name: 'საბიბლიოთეკო საქმიანობა')
      #
      #   expect(patriarch_agency.direct_priorities_on_date(Date.new(2012, 1, 1)))
      #   .to contain_exactly(culture_priority)
      #
      #   expect(patriarch_agency.direct_priorities_on_date(Date.new(2016, 12, 31)))
      #   .to contain_exactly(culture_priority)
      # end
      #
      # it 'assigns priority to patriach spending agency from 2012-2013' do
      #   patriarch_agency = BudgetItem.find(
      #     code: '45 00',
      #     name: 'საქართველოს საპატრიარქო'
      #   )
      #
      #   expect(patriarch_agency.direct_priorities_on_date(Date.new(2012, 1, 1)))
      #   .to contain_exactly(culture_priority)
      #
      #   expect(patriarch_agency.direct_priorities_on_date(Date.new(2013, 12, 31)))
      #   .to contain_exactly(culture_priority)
      #
      #   expect(patriarch_agency.direct_priorities_on_date(Date.new(2014, 1, 1)))
      #   .to be_empty
      # end
      #
      # it 'assigns priority to patriarch tv program from 2014-2016' do
      #   patriarch_tv_program = BudgetItem.find(
      #     code: '45 11',
      #     name: 'საქართველოს საპატრიარქოს ტელევიზიის სუბსიდირების ღონისძიებები'
      #   )
      #
      #   expect(patriarch_tv_program.direct_priorities_on_date(Date.new(2013, 12, 31)))
      #   .to contain_exactly(culture_priority)
      #
      #   expect(patriarch_tv_program.direct_priorities_on_date(Date.new(2014, 1, 1)))
      #   .to contain_exactly(culture_priority)
      #
      #   expect(
      #     patriarch_tv_program.direct_priorities_on_date(Date.new(2016, 12, 31))
      #   ).to contain_exactly(culture_priority)
      # end
    end
  end
end
