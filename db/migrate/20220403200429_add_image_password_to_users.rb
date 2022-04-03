class AddImagePasswordToUsers < ActiveRecord::Migration[5.2]
  def up
    add_column :users, :image_password, :string

    User.all.each do |u|
      password = Devise.friendly_token.first(10)
      u.update!(image_password: password)
    end

    change_column_null :users, :image_password, false
  end

  def down
    remove_column :users, :image_password
  end
end
