class CreateImports < ActiveRecord::Migration[5.1]
  def change
    create_table :imports do |t|
      t.integer :file_length
      t.string :type
      t.timestamps
      t.boolean :procceded, default: false
    end
  end
end
