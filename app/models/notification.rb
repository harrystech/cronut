class Notification < ActiveRecord::Base
  has_many :job_notifications, :dependent => :destroy
  has_many :jobs, :through => :job_notifications, :uniq => true
  attr_accessible :name
  validates :name, :presence => true

  def alert(job)
    raise "ERROR: alert must be defined"
  end

  def early_alert(job)
    raise "ERROR: early_alert must be defined"
  end
end
