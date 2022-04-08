class AddPostDateToSetting < ActiveRecord::Migration[5.2]
  def change
    add_column :settings, :show_post_date, :boolean, default: false
  end
end
