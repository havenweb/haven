class AddSortDateToFeedEntries < ActiveRecord::Migration[5.2]
  def change
    add_column :feed_entries, :sort_date, :datetime
    add_index :feed_entries, :sort_date

    reversible do |dir|
      dir.up do
        FeedEntry.find_each do |f|
          f.sort_date = f.published
          f.save!
        end
      end
      dir.down do
      end
    end

  end
end
