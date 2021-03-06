require 'rails_helper'

RSpec.describe ItemMerger do
  describe '#merge' do
    it 'destroys giver object' do
      receiver = FactoryGirl.create(:program)
      giver = FactoryGirl.create(:program)

      ItemMerger.new(receiver).merge(giver)

      expect(giver.persisted?).to eq(false)
    end

    context 'when receiver and giver do not have same class' do
      it 'throws error' do
        receiver = FactoryGirl.create(:program)
        giver = FactoryGirl.create(:spending_agency)

        expect do
          ItemMerger.new(receiver).merge(giver)
        end.to raise_error(MergeImpossibleError)
      end
    end

    context 'when receiver object has two codes' do
      context 'and giver object has two codes, one of which can be merged' do
        it 'merges giver codes into receiver' do
          receiver = FactoryGirl.create(:program)
          .add_code(FactoryGirl.attributes_for(
            :code,
            number: '01 01',
            start_date: Date.new(2012, 2, 1)
          )).add_code(FactoryGirl.attributes_for(
            :code,
            number: '01 02',
            start_date: Date.new(2012, 3, 1)
          ))

          giver = FactoryGirl.create(:program)
          .add_code(FactoryGirl.attributes_for(
            :code,
            number: '01 01',
            start_date: Date.new(2012, 2, 15)
          )).add_code(FactoryGirl.attributes_for(
            :code,
            number: '01 03',
            start_date: Date.new(2012, 4, 1)
          ))

          ItemMerger.new(receiver).merge(giver)

          expect(receiver.codes.count).to eq(3)
          expect(receiver.code).to eq('01 03')
        end
      end
    end

    context 'when receiver object has two names' do
      context 'and giver object has two names, one of which can be merged' do
        it 'merges giver names into receiver' do
          receiver = FactoryGirl.create(:spending_agency)
          .add_name(FactoryGirl.attributes_for(
            :name,
            text: 'Name 1',
            start_date: Date.new(2012, 2, 1)
          )).add_name(FactoryGirl.attributes_for(
            :name,
            text: 'Name 2',
            start_date: Date.new(2012, 3, 1)
          ))

          giver = FactoryGirl.create(:spending_agency)
          .add_name(FactoryGirl.attributes_for(
            :name,
            text: 'Name 1',
            start_date: Date.new(2012, 2, 15)
          )).add_name(FactoryGirl.attributes_for(
            :name,
            text: 'Name 3',
            start_date: Date.new(2012, 4, 1)
          ))

          ItemMerger.new(receiver).merge(giver)

          expect(receiver.names.count).to eq(3)
          expect(receiver.name).to eq('Name 3')
        end
      end
    end

    context 'when receiver and giver each have two monthly spent finances' do
      let(:receiver) { FactoryGirl.create(:spending_agency) }
      let(:giver) { FactoryGirl.create(:spending_agency) }

      let(:receiver_spent_f_april_2012) do
        time_period = Month.for_date(Date.new(2012, 4, 1))

        FactoryGirl.attributes_for(
          :spent_finance,
          start_date: time_period.start_date,
          end_date: time_period.end_date
        )
      end

      let(:receiver_spent_f_april_2013) do
        time_period = Month.for_date(Date.new(2013, 4, 1))

        FactoryGirl.attributes_for(
          :spent_finance,
          start_date: time_period.start_date,
          end_date: time_period.end_date
        )
      end

      let(:giver_spent_f_may_2013) do
        time_period = Month.for_date(Date.new(2013, 5, 1))

        FactoryGirl.attributes_for(
          :spent_finance,
          start_date: time_period.start_date,
          end_date: time_period.end_date
        )
      end

      let(:giver_spent_f_june_2013) do
        time_period = Month.for_date(Date.new(2013, 6, 1))

        FactoryGirl.attributes_for(
          :spent_finance,
          start_date: time_period.start_date,
          end_date: time_period.end_date
        )
      end

      before :each do
        receiver
        .add_spent_finance(receiver_spent_f_april_2012)
        .add_spent_finance(receiver_spent_f_april_2013)

        giver
        .add_spent_finance(giver_spent_f_may_2013)
        .add_spent_finance(giver_spent_f_june_2013)
      end

      it 'causes receiver object to have four monthly spent finances' do
        ItemMerger.new(receiver).merge(giver)

        expect(receiver.spent_finances.monthly.count).to eq(4)
      end

      it 'merges first monthly spent finance amount by as cumulative within year' do
        ItemMerger.new(receiver).merge(giver)

        expect(receiver.spent_finances.monthly[2].amount).to eq(
          giver_spent_f_may_2013[:amount] - receiver_spent_f_april_2013[:amount]
        )
      end

      it 'merges second monthly spent finance as non cumulative' do
        ItemMerger.new(receiver).merge(giver)

        expect(receiver.spent_finances.monthly[3].amount).to eq(
          giver_spent_f_june_2013[:amount]
        )
      end
    end

    context 'when receiver and giver each have one yearly spent finance' do
      let(:receiver) { FactoryGirl.create(:spending_agency) }
      let(:giver) { FactoryGirl.create(:spending_agency) }

      let(:receiver_spent_f_2012) do
        time_period = Year.for_date(Date.new(2012, 1, 1))

        FactoryGirl.attributes_for(
          :spent_finance,
          start_date: time_period.start_date,
          end_date: time_period.end_date
        )
      end

      let(:giver_spent_f_2013) do
        time_period = Year.for_date(Date.new(2013, 1, 1))

        FactoryGirl.attributes_for(
          :spent_finance,
          start_date: time_period.start_date,
          end_date: time_period.end_date
        )
      end

      before :each do
        receiver.add_spent_finance(receiver_spent_f_2012)
        giver.add_spent_finance(giver_spent_f_2013)
      end

      it 'causes receiver to have two yearly spent finances' do
        ItemMerger.new(receiver).merge(giver)

        expect(receiver.spent_finances.yearly.count).to eq(2)
      end

      it "takes giver's 2013 finance amount directly" do
        ItemMerger.new(receiver).merge(giver)

        expect(receiver.spent_finances.yearly.last.amount).to eq(
          giver_spent_f_2013[:amount]
        )
      end
    end

    context 'when receiver has two and giver has three planned finances' do
      let(:receiver) { FactoryGirl.create(:program) }
      let(:giver) { FactoryGirl.create(:program) }

      let(:receiver_planned_f_q4_2012_oct) do
        time_period = Quarter.for_date(Date.new(2012, 10, 1))

        FactoryGirl.attributes_for(
          :planned_finance,
          start_date: time_period.start_date,
          end_date: time_period.end_date,
          announce_date: time_period.start_date
        )
      end

      let(:receiver_planned_f_q1_2013_jan) do
        time_period = Quarter.for_date(Date.new(2013, 1, 1))

        FactoryGirl.attributes_for(
          :planned_finance,
          start_date: time_period.start_date,
          end_date: time_period.end_date,
          announce_date: time_period.start_date
        )
      end

      let(:giver_planned_f_q2_2013_april) do
        time_period = Quarter.for_date(Date.new(2013, 4, 1))

        FactoryGirl.attributes_for(
          :planned_finance,
          start_date: time_period.start_date,
          end_date: time_period.end_date,
          announce_date: time_period.start_date
        )
      end

      let(:giver_planned_f_q2_2013_may) do
        time_period = Quarter.for_date(Date.new(2013, 4, 1))

        FactoryGirl.attributes_for(
          :planned_finance,
          start_date: time_period.start_date,
          end_date: time_period.end_date,
          announce_date: time_period.start_date.next_month
        )
      end

      let(:giver_planned_f_q3_2013_july) do
        time_period = Quarter.for_date(Date.new(2013, 7, 1))

        FactoryGirl.attributes_for(
          :planned_finance,
          start_date: time_period.start_date,
          end_date: time_period.end_date,
          announce_date: time_period.start_date
        )
      end

      before :each do
        receiver
        .add_planned_finance(receiver_planned_f_q4_2012_oct)
        .add_planned_finance(receiver_planned_f_q1_2013_jan)

        giver
        .add_planned_finance(giver_planned_f_q2_2013_april)
        .add_planned_finance(giver_planned_f_q2_2013_may)
        .add_planned_finance(giver_planned_f_q3_2013_july)
      end

      it 'causes receiver to have five planned finances' do
        ItemMerger.new(receiver).merge(giver)

        expect(receiver.all_planned_finances.count).to eq(5)
      end

      it "saves planned finances in giver's first quarter cumulatively within year" do
        ItemMerger.new(receiver).merge(giver)

        expect(receiver.all_planned_finances[2].amount).to eq(
          giver_planned_f_q2_2013_april[:amount] -
          receiver_planned_f_q1_2013_jan[:amount]
        )

        expect(receiver.all_planned_finances[3].amount).to eq(
          giver_planned_f_q2_2013_may[:amount] -
          receiver_planned_f_q1_2013_jan[:amount]
        )
      end

      it "saves planned finance in giver's second quarter non cumulatively" do
        ItemMerger.new(receiver).merge(giver)

        expect(receiver.all_planned_finances[4].amount).to eq(
          giver_planned_f_q3_2013_july[:amount]
        )
      end
    end

    context 'when receiver and giver each have one yearly planned finance' do
      let(:receiver) { FactoryGirl.create(:program) }
      let(:giver) { FactoryGirl.create(:program) }

      let(:receiver_planned_f_2012) do
        time_period = Year.for_date(Date.new(2012, 1, 1))

        FactoryGirl.attributes_for(
          :planned_finance,
          start_date: time_period.start_date,
          end_date: time_period.end_date,
          announce_date: time_period.start_date
        )
      end

      let(:giver_planned_f_2013) do
        time_period = Year.for_date(Date.new(2013, 1, 1))

        FactoryGirl.attributes_for(
          :planned_finance,
          start_date: time_period.start_date,
          end_date: time_period.end_date,
          announce_date: time_period.start_date
        )
      end

      before :each do
        receiver.add_planned_finance(receiver_planned_f_2012)
        giver.add_planned_finance(giver_planned_f_2013)
      end

      it 'causes receiver to have two yearly planned finances' do
        ItemMerger.new(receiver).merge(giver)

        expect(receiver.planned_finances.yearly.count).to eq(2)
      end

      it "merges giver's planned finance as non cumulative" do
        ItemMerger.new(receiver).merge(giver)

        expect(receiver.planned_finances.yearly.last.amount).to eq(
          giver_planned_f_2013[:amount]
        )
      end
    end

    context 'when receiver has one and giver has two possible duplicates' do
      context 'and one of the duplicates is the same' do
        let(:receiver) { FactoryGirl.create(:program) }
        let(:giver) { FactoryGirl.create(:program) }

        let(:possible_duplicate1) { FactoryGirl.create(:program) }
        let(:possible_duplicate2) { FactoryGirl.create(:program) }

        before :each do
          receiver.save_possible_duplicates([
            possible_duplicate1
          ], date_when_found: Date.new(2012, 1, 1))

          giver.save_possible_duplicates([
            possible_duplicate1,
            possible_duplicate2
          ], date_when_found: Date.new(2014, 1, 1))
        end

        it 'causes receiver to have two possible duplicates' do
          ItemMerger.new(receiver).merge(giver)

          expect(receiver.possible_duplicates.count).to eq(2)
        end
      end
    end

    context 'when giver is spending agency with programs' do
      let(:receiver) { FactoryGirl.create(:spending_agency) }
      let(:giver) { FactoryGirl.create(:spending_agency) }

      it 'changes spending agency of those programs to receiver' do
        programs = FactoryGirl.create_list(:program, 2, spending_agency: giver)

        ItemMerger.new(receiver).merge(giver)
        expect(receiver.all_programs).to contain_exactly(*programs)
      end
    end

    context 'when giver is program with descendant programs' do
      let(:receiver) { create(:program) }
      let(:giver) { create(:program) }

      it 'changes parent_program of only child programs to receiver' do
        child_programs = create_list(:program, 2, parent_program: giver)
        grandchild_program = create(:program, parent_program: child_programs[0])

        ItemMerger.new(receiver).merge(giver)
        expect(receiver.child_programs).to contain_exactly(*child_programs)
        expect(grandchild_program.parent_program).to eq(child_programs[0])
      end
    end

    context 'when giver has perma_ids' do
      let(:receiver) { FactoryGirl.create(:program) }
      let(:giver) { FactoryGirl.create(:program) }

      it 'changes perma_idable of those perma_ids to receiver' do
        perma_id1 = FactoryGirl.create(:perma_id, perma_idable: giver)
        perma_id2 = FactoryGirl.create(:perma_id, perma_idable: giver)

        ItemMerger.new(receiver).merge(giver)
        expect(receiver.perma_ids).to include(perma_id1, perma_id2)
      end
    end

    context 'when giver has priority connections' do
      let(:receiver) { FactoryGirl.create(:spending_agency) }
      let(:giver) { FactoryGirl.create(:spending_agency) }

      it 'changes priority_connectable on priority connections to receiver' do
        create_list(:priority_connection, 3, priority_connectable: giver)
        create(:priority_connection)

        ItemMerger.new(receiver).merge(giver)
        expect(receiver.priority_connections.length).to eq(3)
      end
    end

    context 'when giver has directly connected priority and receiver has program' do
      let!(:receiver) { FactoryGirl.create(:spending_agency) }
      let!(:giver) { FactoryGirl.create(:spending_agency) }

      let!(:receiver_child_program) do
        create(:program, spending_agency: receiver)
      end

      before do
        create(:priority_connection, direct: true, priority_connectable: giver)

        ItemMerger.new(receiver).merge(giver)
      end

      it 'moves direct priority connection to receiver' do
        expect(receiver.priority_connections.direct.length).to eq(1)
      end

      it "indirectly connects receiver's program to priority" do
        expect(receiver_child_program.priority_connections.indirect.length)
        .to eq(1)
      end
    end
  end
end
