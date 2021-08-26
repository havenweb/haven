class CreateFeedEntries < ActiveRecord::Migration[5.2]
  def change
    create_table :feed_entries do |t|
      t.string :title
      t.text :content
      t.string :link
      t.string :guid, index: true
      t.datetime :published, index: true
      t.references :feed, foreign_key: true

      t.timestamps
    end
  end
end
