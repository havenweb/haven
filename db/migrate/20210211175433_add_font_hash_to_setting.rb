class AddFontHashToSetting < ActiveRecord::Migration[5.2]
  def change
    add_column :settings, :font_hash, :string
  end
end
