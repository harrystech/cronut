class CreateNotifications < ActiveRecord::Migration
  def change
    create_table :notifications do |t|
      t.string :name, :null => false
      t.string :type, :null => false
      t.string :value

      t.timestamps
    end

    add_index :notifications, :type

    create_table :jobs_notifications, id: false do |t|
      t.belongs_to :job
      t.belongs_to :notification
    end
  end
end
