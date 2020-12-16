class AddUserAndPostRefToComments < ActiveRecord::Migration[5.2]
  def change
    add_reference :comments, :author, foreign_key: { to_table: :users}
    add_reference :comments, :post
  end
end
