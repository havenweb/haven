class AddStatusAndLastUpdateToFeeds < ActiveRecord::Migration[5.2]
  def change
    add_column :feeds, :last_update, :datetime
    add_column :feeds, :status, :integer, default: 0
  end
end
