class AddBylineToSetting < ActiveRecord::Migration[5.2]
  def change
    add_column :settings, :byline, :boolean, default: true
  end
end
