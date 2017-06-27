class CreateMediaTable < ActiveRecord::Migration[5.0]

  def up
    create_table :media do |t|
      t.date :story_published_at
      t.boolean :published, default: false
      t.date :published_at

      t.timestamps null: false
    end

    create_table :medium_images do |t|
      t.string :image
    end

    # Medium.create_translation_table! title: :string, author: :string,
    #   description: :text, media_name: :string, embed: :text,
    #   source: :string, image_id: :integer

    create_table "medium_translations", :force => true do |t|
      t.integer  :medium_id
      t.string   :locale
      t.string :title
      t.string :author
      t.text :description
      t.string :media_name
      t.text :embed
      t.string :source
      t.integer :image_id

      # any other translated attributes would appear here
      t.datetime "created_at",  :null => false
      t.datetime "updated_at",  :null => false
    end


  end

  def down
    drop_table :media
    drop_table :medium_images
    Medium.drop_translation_table!
  end
end
