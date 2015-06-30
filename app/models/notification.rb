class Notification < ActiveRecord::Base
  has_many :job_notifications, :dependent => :destroy
  has_many :jobs, -> { uniq }, :through => :job_notifications

  validates :name, :presence => true

  def alert(job)
    raise "ERROR: alert must be defined"
  end

  def early_alert(job)
    raise "ERROR: early_alert must be defined"
  end

  def recover(job, event_key)
    # Implementation of this is optional
  end
end
