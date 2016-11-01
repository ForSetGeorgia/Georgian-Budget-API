class Name < ApplicationRecord
  belongs_to :nameable, polymorphic: true

  translates :text, fallbacks_for_empty_translations: true
  globalize_accessors locales: [:en, :ka], attributes: [:text]

  validates :start_date, uniqueness: { scope: [:nameable_type, :nameable_id] }, presence: true
  validates :nameable, presence: true

  def text=(initial_text)
    self[:text] = Name.clean_text(initial_text)
  end

  def self.texts_represent_same_budget_item?(text1, text2)
    aggressively_clean_text(text1) == aggressively_clean_text(text2)
  end

  private

  def self.aggressively_clean_text(text)
    clean_text(
      text
      .gsub('—', ' ')
      .gsub('-', ' ')
      .gsub(',', ' ')
      .gsub('(', ' ')
      .gsub(')', ' ')
      .gsub('/', ' ')
      .gsub('\\', ' ')
    )
  end

  def self.clean_text(text)
    text
    .gsub(/\s+/, ' ')
    .strip
  end
end
