class CreateLoginLinks < ActiveRecord::Migration[5.2]
  def change
    create_table :login_links do |t|
      t.string :token
      t.references :user, foreign_key: true

      t.timestamps
    end
  end
end
