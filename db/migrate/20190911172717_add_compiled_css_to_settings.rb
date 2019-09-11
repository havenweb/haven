class AddCompiledCssToSettings < ActiveRecord::Migration[5.2]
  def change
    add_column :settings, :compiled_css, :string
  end
end
