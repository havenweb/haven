class AddCommentsToSettings < ActiveRecord::Migration[5.2]
  def change
    add_column :settings, :comments, :boolean, default: false
  end
end
