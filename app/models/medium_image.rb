class MediumImage < ApplicationRecord

  mount_uploader :image, ImageUploader

  I18n.available_locales.each do |locale|
    attr_accessor "image_#{locale}"
  end

  validates :image, presence: :true
end
