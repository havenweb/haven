class CreateIndieAuthTokens < ActiveRecord::Migration[6.1]
  def change
    create_table :indie_auth_tokens do |t|
      t.bigint :user_id
      t.string :access_token
      t.string :scope
      t.string :client_id

      t.timestamps
      
      t.index ["access_token"], name: "index indie_auth_tokens_on_access_token", unique: true
    end
  end
end
