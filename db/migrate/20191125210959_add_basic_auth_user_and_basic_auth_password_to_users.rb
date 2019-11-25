class AddBasicAuthUserAndBasicAuthPasswordToUsers < ActiveRecord::Migration[5.2]
  def up
    add_column :users, :basic_auth_username, :string
    add_column :users, :basic_auth_password, :string

    User.all.each do |u|
      username = Devise.friendly_token.first(20)
      until (User.find_by basic_auth_username: username).nil? do
        username = Devise.friendly_token.first(20)
      end
      password = Devise.friendly_token.first(20)
      u.update!(basic_auth_username: username, basic_auth_password: password)
    end

    change_column_null :users, :basic_auth_username, false
    change_column_null :users, :basic_auth_password, false
    add_index :users, :basic_auth_username, unique: true
  end

  def down
    remove_column :users, :basic_auth_username
    remove_column :users, :basic_auth_password
  end


end
