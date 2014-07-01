class PagerdutyNotification < Notification
  attr_accessible :value
  validates :value, :presence => true

  def self.model_name
    superclass.model_name
  end

  def alert(job)
    pd = Pagerduty.new(self.value)
    pd.trigger("Job \"#{job.name}\" didn't run")
  end

  def early_alert(job)
    pd = Pagerduty.new(self.value)
    pd.trigger("Job \"#{job.name}\" ran too early")
  end
end