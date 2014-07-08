class JobNotification < ActiveRecord::Base
  belongs_to :job
  belongs_to :notification

  def alert
    notification.alert(job)
  end

  def early_alert
    notification.early_alert(job)
  end
end