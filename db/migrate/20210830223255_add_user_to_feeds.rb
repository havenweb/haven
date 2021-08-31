class AddUserToFeeds < ActiveRecord::Migration[5.2]
  def up
    add_reference :feeds, :user, foreign_key: true, index: true

    # Assign all feeds to first admin user
    user = User.find_by(admin: 1)
    Feed.find_each do |f|
      f.update!(user: user)
    end
  end

  def down
    remove_reference :feeds, :user, foreign_key: true, index: true
    remove_reference :feed_entries, :user, foreign_key: true, index: true
  end
end
