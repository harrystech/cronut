class PagerdutyNotification < Notification

  validates :value, :presence => true

  def self.model_name
    superclass.model_name
  end

  def alert(job)
    pd = Pagerduty.new(self.value)
    return pd.trigger("Job \"#{job.name}\" didn't run").incident_key
  end

  def early_alert(job)
    pd = Pagerduty.new(self.value)
    pd.trigger("Job \"#{job.name}\" ran too early")
  end

  def recover(job, event_key)
    if event_key
      incident = Pagerduty.new(self.value).get_incident(event_key)
      incident.resolve("Job ran at #{job.last_successful_time_str}")
    end
  end
end