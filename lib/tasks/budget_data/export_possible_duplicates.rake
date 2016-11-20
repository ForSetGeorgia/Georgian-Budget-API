namespace :budget_data do
  desc 'Export CSV of possible duplicate budget items'
  task :export_possible_duplicate_budget_items, [:locale] => :environment do |t, args|
    I18n.locale = args[:locale]

    file_name = "possible_duplicate_budget_items_#{I18n.locale}.csv"
    csv_file_path = Rails.root.join('tmp', file_name)

    possible_duplicate_pairs = PossibleDuplicatePair
    .all
    .includes(:item1)
    .includes(:item2)
    .order(pair_type: :desc)
    .sort_by do |pair|
      pair.item1.code
    end

    require 'csv'
    CSV.open(csv_file_path, 'wb') do |csv|
      csv << [
        'Budget Item Type',
        'Budget Item 1 Code',
        'Budget Item 2 Code',
        'Budget Item 1 Name',
        'Budget Item 2 Name',
        'Budget Item 1 Dates',
        'Budget Item 2 Dates',
        'Marked on Date',
        'Priority Names (if different)',
        'Merge? (yes / no)'
      ]

      possible_duplicate_pairs.each do |possible_duplicate_pair|
        item1 = possible_duplicate_pair.item1
        item2 = possible_duplicate_pair.item2

        csv << [
          possible_duplicate_pair.pair_type,
          possible_duplicate_pair.item1_code_when_found,
          possible_duplicate_pair.item2_code_when_found,
          possible_duplicate_pair.item1_name_when_found,
          possible_duplicate_pair.item2_name_when_found,
          "#{item1.start_date} - #{item1.end_date}",
          "#{item2.start_date} - #{item2.end_date}",
          possible_duplicate_pair.date_when_found,
          possible_duplicate_pair.priorities_differ? ? "Item 1 priority: #{item1.priority.name} |||||| Item 2 priority: #{item2.priority.name}" : '',
          ''
        ]
      end
    end

    puts "Finished exporting CSV of possible duplicate pairs"
    puts "File path: #{csv_file_path}"
    puts "Number of Possible Duplicate Pairs: #{possible_duplicate_pairs.count}"
  end
end
