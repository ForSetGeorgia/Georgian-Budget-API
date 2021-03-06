require 'rails_helper'

RSpec.shared_examples_for 'Nameable' do
  let(:described_class_sym) { described_class.to_s.underscore.to_sym }

  let(:nameable1) { FactoryGirl.create(described_class_sym) }
  let(:nameable2) { FactoryGirl.create(described_class_sym) }
  let(:nameable3) { FactoryGirl.create(described_class_sym) }

  let(:name_start_date) { Date.new(2015, 01, 01) }

  let(:name_attr1a) { FactoryGirl.attributes_for(:name) }

  let(:name_attr1b) do
    FactoryGirl.attributes_for(
      :name,
      start_date: name_attr1a[:start_date] + 1)
  end

  let(:name_attr1c) do
    FactoryGirl.attributes_for(
      :name,
      start_date: name_attr1b[:start_date] + 1)
  end

  let(:name_attr2a) do
    FactoryGirl.attributes_for(
      :name,
      start_date: Date.new(2014, 1, 1))
  end

  let(:name_attr2b) do
    FactoryGirl.attributes_for(
      :name,
      start_date: name_attr2a[:start_date] + 1)
  end

  let(:name_attr3a) do
    FactoryGirl.attributes_for(
      :name,
      start_date: Date.new(2014, 1, 1))
  end

  describe '#destroy' do
    it 'destroys associated names' do
      nameable1
      .add_name(name_attr1a)
      .add_name(name_attr1b)

      name_ids = nameable1.names.pluck(:id)

      nameable1.reload
      nameable1.destroy

      expect(Name.exists?(name_ids[0])).to eq(false)
      expect(Name.exists?(name_ids[1])).to eq(false)
    end
  end

  describe '#name' do
    it 'returns most recent name text' do
      nameable1
      .add_name(name_attr1a)
      .add_name(name_attr1b)
      .reload

      expect(nameable1.name).to eq(name_attr1b[:text_en])
    end
  end

  describe '#name_{locale} methods' do
    it 'return correct translations of most recent name text' do
      georgian_name = 'Georgian name!'
      english_name = 'English name!'
      name_attr1a[:text_ka] = georgian_name
      name_attr1a[:text_en] = english_name

      nameable1.add_name(name_attr1a)

      expect(nameable1.name_ka).to eq(georgian_name)
      expect(nameable1.name_en).to eq(english_name)
    end
  end

  describe '#recent_name_object' do
    it 'returns the most recent name object' do
      nameable1
      .add_name(name_attr1a)
      .add_name(name_attr1b)
      .reload

      expect(nameable1.recent_name_object.text).to eq(name_attr1b[:text_en])
    end
  end

  describe '#name_on_date' do
    let(:jan_1_2012) { Date.new(2012, 1, 1) }

    context 'when nameable has no names' do
      it 'returns nil' do
        expect(nameable1.name_on_date(jan_1_2012)).to eq(nil)
      end
    end

    context 'when nameable has one name with start date before arg date' do
      it 'returns that name' do
        name_attr1c[:start_date] = jan_1_2012 - 1
        name = nameable1.add_name(name_attr1c, return_name: true)

        expect(
          nameable1.name_on_date(jan_1_2012)
        ).to eq(name)
      end
    end

    context 'when nameable has one name with start date on arg date' do
      it 'returns that name' do
        name_attr1c[:start_date] = jan_1_2012
        name = nameable1.add_name(name_attr1c, return_name: true)

        expect(
          nameable1.name_on_date(jan_1_2012)
        ).to eq(name)
      end
    end

    context 'when nameable has one name with start date after arg date' do
      it 'returns nil' do
        name_attr1c[:start_date] = jan_1_2012 + 1
        nameable1.add_name(name_attr1c)

        expect(
          nameable1.name_on_date(jan_1_2012)
        ).to eq(nil)
      end
    end

    context 'when nameable has three names' do
      context 'with start dates before, on, and after arg date' do
        it 'returns name with start date on arg date' do
          name_attr1a[:start_date] = jan_1_2012 - 1
          nameable1.add_name(name_attr1a)

          name_attr1b[:start_date] = jan_1_2012
          jan_1_2012_name = nameable1.add_name(
            name_attr1b,
            return_name: true)

          name_attr1c[:start_date] = jan_1_2012 + 1
          nameable1.add_name(name_attr1c)

          expect(
            nameable1.name_on_date(jan_1_2012)
          ).to eq(jan_1_2012_name)
        end
      end
    end
  end

  describe '.with_name_in_history' do
    it 'returns nameables with name' do
      nameable1.add_name(name_attr1a)
      nameable2.add_name(name_attr2a)

      name_attr3a[:text_en] = name_attr1a[:text_en]
      nameable3.add_name(name_attr3a)

      expect(described_class.with_name_in_history(name_attr1a[:text_en]))
      .to match_array([nameable1, nameable3])
    end
  end

  describe '#names' do
    it 'gets names in order of start date' do
      nameable1.add_name(name_attr1b)
      nameable1.add_name(name_attr1a)

      nameable1.reload
      expect(nameable1.names[0].text).to eq(name_attr1a[:text_en])
      expect(nameable1.names[1].text).to eq(name_attr1b[:text_en])
    end
  end

  describe '#add_name' do
    context 'when name is invalid' do
      it 'raises error' do
        name_attr1a[:start_date] = nil
        expect { nameable1.add_name(name_attr1a) }
        .to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context 'when nameable has start date after name start date' do
      it "updates nameable's start date to name start date" do
        nameable1.start_date = Date.new(2012, 1, 2)
        nameable1.save

        name_attr1a[:start_date] = Date.new(2012, 1, 1)

        nameable1.add_name(name_attr1a)

        nameable1.reload
        expect(nameable1.start_date).to eq(Date.new(2012, 1, 1))
      end
    end

    context 'when nameable has no names' do
      it 'causes nameable to have one name' do
        nameable1.add_name(name_attr1a)
        nameable1.reload

        expect(nameable1.names.length).to eq(1)
      end

      describe 'adds name to nameable' do
        it 'with correct start date' do
          nameable1.add_name(name_attr1a)
          nameable1.reload

          expect(nameable1.names[0].start_date).to eq(name_attr1a[:start_date])
        end

        it 'with correct text' do
          nameable1.add_name(name_attr1a)
          nameable1.reload

          expect(nameable1.names[0].text).to eq(name_attr1a[:text_en])
        end

        it 'marked as most recent name of nameable' do
          nameable1.add_name(name_attr1a)
          nameable1.reload

          expect(nameable1.recent_name_object.text).to eq(name_attr1a[:text_en])
        end
      end
    end

    context 'when name has earlier sibling' do
      before :example do
        nameable1.add_name(name_attr1a)
      end

      context 'text matches earlier sibling' do
        before :example do
          name_attr1b[:text_en] = name_attr1a[:text_en]
        end

        it 'causes nameable to have 1 name' do
          nameable1.add_name(name_attr1b)
          nameable1.reload

          expect(nameable1.names.length).to eq(1)
        end

        describe 'merges the names into one name' do
          it 'with earlier start_date' do
            nameable1.add_name(name_attr1b)
            nameable1.reload

            expect(nameable1.names[0].start_date).to eq(name_attr1a[:start_date])
          end

          it 'marked as most recent name of nameable' do
            nameable1.add_name(name_attr1b)
            nameable1.reload

            expect(nameable1.recent_name_object.text).to eq(name_attr1a[:text_en])
          end
        end
      end

      context 'and name texts are different' do
        it 'adds another name object' do
          nameable1.add_name(name_attr1b)
          nameable1.reload

          expect(nameable1.names.length).to eq(2)
        end

        describe 'adds another name object' do
          it 'with provided start date' do
            nameable1.add_name(name_attr1b)
            nameable1.reload

            expect(nameable1.names[1].start_date).to eq(name_attr1b[:start_date])
          end

          it 'marked as most recent name of nameable' do
            nameable1.add_name(name_attr1b)
            nameable1.reload

            expect(nameable1.recent_name_object.text).to eq(name_attr1b[:text_en])
          end
        end
      end
    end

    context 'when name has more recent sibling' do
      before :example do
        nameable1.add_name(name_attr1b)
      end

      context 'and text matches sibling' do
        before :example do
          name_attr1a[:text_en] = name_attr1b[:text_en]
        end

        it 'causes nameable to have 1 name' do
          nameable1.add_name(name_attr1a)
          nameable1.reload

          expect(nameable1.names.length).to eq(1)
        end

        describe 'merges the names into one name' do
          it 'with earlier start date' do
            nameable1.add_name(name_attr1a)
            nameable1.reload

            expect(nameable1.names[0].start_date)
            .to eq(name_attr1a[:start_date])
          end

          it 'marked as most recent name of nameable' do
            nameable1.add_name(name_attr1a)
            nameable1.reload

            expect(nameable1.recent_name_object.text).to eq(name_attr1a[:text_en])
          end
        end
      end

      context 'and name texts are different' do
        it 'adds another name object' do
          nameable1.add_name(name_attr1a)
          nameable1.reload

          expect(nameable1.names.length).to eq(2)
        end

        describe 'adds another name object' do
          it 'with provided start date' do
            nameable1.add_name(name_attr1a)
            nameable1.reload

            expect(nameable1.names[0].start_date).to eq(name_attr1a[:start_date])
          end

          it 'not marked as most recent name' do
            nameable1.add_name(name_attr1a)
            nameable1.reload

            expect(nameable1.recent_name_object.text).to_not eq(name_attr1a[:text_en])
          end
        end
      end
    end

    context 'when name has two earlier siblings' do
      before :example do
        nameable1
        .add_name(name_attr1a)
        .add_name(name_attr1b)
      end

      context 'and text matches earliest sibling (but not later sibling)' do
        it 'adds another name object' do
          name_attr1c[:text_en] = name_attr1a[:text_en]

          nameable1.add_name(name_attr1c)

          nameable1.reload

          expect(nameable1.names.length).to eq(3)
        end
      end
    end
  end

  describe '#take_name' do
    let(:name) { FactoryGirl.create(:name) }

    it "takes name away from name's old nameable" do
      old_nameable = name.nameable
      nameable1.take_name(name)

      expect(old_nameable.names.count).to eq(0)
    end

    context 'when nameable has no names' do
      it 'causes nameable to have one name' do
        nameable1.take_name(name)

        expect(nameable1.names.count).to eq(1)
      end
    end
  end

  describe '.with_most_recent_names' do
    it 'loads each nameable with its most recent name object' do
      nameable1
      .add_name(name_attr1a)
      .add_name(name_attr1b)

      nameable2
      .add_name(name_attr2a)
      .add_name(name_attr2b)

      nameables_with_names = described_class.with_most_recent_names

      nameable1_with_names = nameables_with_names.find do |nameable|
        nameable.id == nameable1.id
      end

      nameable2_with_names = nameables_with_names.find do |nameable|
        nameable.id == nameable2.id
      end

      expect(nameable1_with_names.reload.name).to eq(name_attr1b[:text_en])
      expect(nameable2_with_names.reload.name).to eq(name_attr2b[:text_en])
    end

    it 'issues just 1 query (with subsequent nameable.name calls)' do
      nameable1.add_name(name_attr1a)
      nameable2.add_name(name_attr2a)

      expect do
        nameables_with_names = described_class.all.with_most_recent_names
        nameables_with_names[0].name
        nameables_with_names[1].name
      end.to query_limit_eq(1)
    end

    it 'preloads only one name for each nameable' do
      nameable1
      .add_name(name_attr1a)
      .add_name(name_attr1b)

      nameable2
      .add_name(name_attr2a)
      .add_name(name_attr2b)

      nameables_with_names = described_class.all.with_most_recent_names

      expect(nameables_with_names[0].names.length).to eq(1)
      expect(nameables_with_names[1].names.length).to eq(1)
    end
  end
end
