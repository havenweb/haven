class CreateSettings < ActiveRecord::Migration[5.2]
  def change
    create_table :settings do |t|
      t.string :title
      t.string :subtitle
      t.string :author
      t.string :visibility
      t.text :css

      t.timestamps
    end
  end
end
