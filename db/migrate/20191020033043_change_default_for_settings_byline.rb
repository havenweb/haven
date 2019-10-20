class ChangeDefaultForSettingsByline < ActiveRecord::Migration[5.2]
  def change
    change_column_default :settings, :byline, from: true, to: false
  end
end
