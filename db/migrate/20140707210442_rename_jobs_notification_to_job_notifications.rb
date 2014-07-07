class RenameJobsNotificationToJobNotifications < ActiveRecord::Migration
  def change
  	rename_table :jobs_notifications, :job_notifications
  	add_index :job_notifications, [:job_id, :notification_id], :unique => true
  end
end
