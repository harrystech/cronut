class AddPrimaryKeyToJobsNotifications < ActiveRecord::Migration
  def change
  	add_column :jobs_notifications, :id, :primary_key
  end
end
