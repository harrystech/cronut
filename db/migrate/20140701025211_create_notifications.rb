class CreateNotifications < ActiveRecord::Migration
  def change
    create_table :notifications do |t|
      t.integer :job_id, :null => false
      t.string :type, :null => false
      t.string :email      

      t.timestamps
    end

    add_index :notifications, [:job_id, :type]
  end
end
