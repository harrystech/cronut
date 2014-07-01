class PagerdutyNotification < Notification

  def alert
    pd = Pagerduty.new(ENV["PAGERDUTY_SERVICE_KEY"])
    pd.trigger("Job \"#{job.name}\" didn't run")
  end

  def to_s
  	return "Pagerduty"
  end
end