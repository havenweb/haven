class RemoveAuthorFromSettings < ActiveRecord::Migration[5.2]
  def change
    remove_column :settings, :author, :string
  end
end
