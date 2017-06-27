# encoding: utf-8

class ImageUploader < CarrierWave::Uploader::Base
  # include CarrierWave Backgrounder
  # include ::CarrierWave::Backgrounder::Delay

  # include CarrierWave MiniMagick
  include CarrierWave::MiniMagick

  # Choose what kind of storage to use for this uploader - either on server or on Amazon S3, depending
  # of 'image_storage' value in Settings table.
  # image_storage = Rails.cache.fetch(CACHE_IMAGE_STORAGE) {Setting.find_or_create_by(key: 'image_storage').value}
  # if (image_storage == IMAGE_ON_SERVER)
  #   storage :file
  # else
  #   storage :fog
  # end
  storage :file

  # Override the directory where uploaded files will be stored.
  # This is a sensible default for uploaders that are meant to be mounted:
  def store_dir
    "system/media/#{model.id}"
  end

  # Provide a default URL as a default if there hasn't been a file uploaded:
  #def default_url
  #   # For Rails 3.1+ asset pipeline compatibility:
  #   # ActionController::Base.helpers.asset_path("fallback/" + [version_name, "default.png"].compact.join('_'))
  #
  #   "/images/fallback/" + [version_name, "default.png"].compact.join('_')
  #   'being_processed.png' #rails will look at 'app/assets/images/default_image.png'
  #end

  # Process files as they are uploaded:
  # process :scale => [200, 300]
  #
  # def scale(width, height)
  #   # do something
  # end

  def filename
    "original.#{model.image.file.extension}" if original_filename
  end

  # Create different versions of your uploaded files:
  version :thumb do
    process :resize_to_fill => [309, 206]
    process :convert => 'jpg'
    def full_filename (for_file = model.image.file)
      "thumb.jpg"
    end
  end

  version :normal do
    process :resize_to_fit => [1200, 800]
    process :convert => 'jpg'
    def full_filename (for_file = model.image.file)
      "normal.jpg"
    end
  end

  # Add a white list of extensions which are allowed to be uploaded.
  # For images you might use something like this:
  def extension_white_list
    %w(jpg jpeg gif png)
  end

  # Override the filename of the uploaded files:
  # Avoid using model.id or version_name here, see uploader/store.rb for details.
  # def filename
  #   "something.jpg" if original_filename
  # end

  def size_range
    1..5.megabytes
  end
end
