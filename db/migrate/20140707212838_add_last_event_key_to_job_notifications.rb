class AddLastEventKeyToJobNotifications < ActiveRecord::Migration
  def change
    add_column :job_notifications, :last_event_key, :string
  end
end
