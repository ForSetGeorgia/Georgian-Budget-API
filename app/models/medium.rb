class Medium < ApplicationRecord
  #######################
  ## TRANSLATIONS

  translates :title, :author, :description, :media_name, :embed, :source, :image_id, :fallbacks_for_empty_translations => true
  globalize_accessors


  #######################
  ## VALIDATIONS

  # has_one :medium_image, class_name: Translation, foreign_key: :image_id
  # accepts_nested_attributes_for :medium_image, :allow_destroy => true

  validates :title, :author, :description, :media_name, :source, presence: :true
  validates :embed, presence: { if: -> { image_id.blank? } }
  validates :image_id, presence: { if: -> { embed.blank? } }

  #######################
  ## SCOPES

  def self.sorted
    order(story_published_at: :desc )
  end

  def self.published
    where(published: true)
  end

  #######################
  ## HELPERS

  def image
    m = MediumImage.find_by(id: self.image_id)
    m.present? ? m.image : nil
  end

  def has_locale_image_id(locale)
    self.send("image_id_#{locale}").present?
  end

  def direct_image_id(locale)
    self.send("image_id_#{locale}")
  end

  def direct_image(locale)
    direct_image_id = direct_image_id(locale)
    m = nil
    if direct_image_id.present?
      m = MediumImage.find_by(id: direct_image_id)
    end

    m.present? ? m.image : nil
  end



  #######################
  #######################
  def as_json options={}
    tmp = {}
    if self.embed.present?
      tmp[:media] = self.embed
    else
      tmp[:media] = ActionController::Base.helpers.image_tag(self.image.normal.url).html_safe if self.image.present?
    end

    {
      title: self.title,
      author: self.author,
      description: self.description,
      media_name: self.media_name,
      source: self.source,
      published_at: self.story_published_at
    }.merge(tmp)
  end
end
