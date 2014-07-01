class CreateJobs < ActiveRecord::Migration
  def change
    create_table :jobs do |t|
      t.string :name, :null => false
      t.datetime :last_successful_time
      t.datetime :next_scheduled_time, :null => false
      t.string :public_id, :null => false
      t.string :type, :null => false
      t.integer :frequency
      t.string :cron_expression
      t.integer :buffer_time

      t.timestamps
    end

    add_index :jobs, :public_id
    add_index :jobs, :next_scheduled_time
  end
end
