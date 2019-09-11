class AddCssHashToSettings < ActiveRecord::Migration[5.2]
  def change
    add_column :settings, :css_hash, :string
  end
end
