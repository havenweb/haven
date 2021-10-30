class AddAudioToFeedEntries < ActiveRecord::Migration[5.2]
  def change
    add_column :feed_entries, :audio, :string
  end
end
