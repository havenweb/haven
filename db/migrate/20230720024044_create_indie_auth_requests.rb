class CreateIndieAuthRequests < ActiveRecord::Migration[6.1]
  def change
    create_table :indie_auth_requests do |t|
      t.bigint "user_id"
      t.string :code
      t.string :state
      t.string :code_challenge
      t.string :client_id
      t.string :scope
      t.integer :used, default: 0

      t.timestamps

      t.index ["code"], name: "index_indie_auth_requests_on_code", unique: true
    end
    add_foreign_key :indie_auth_requests, :users

  end
end
