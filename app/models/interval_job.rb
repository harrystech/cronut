class IntervalJob < Job
  validates :frequency, :presence => true

  # attr_accessible :frequency

  def self.model_name
    superclass.model_name
  end

  def frequency_str
    return Job.time_str(frequency)
  end

  private
  def calculate_next_scheduled_time(now = Time.now)
    return now + frequency.seconds + extra_time
  end
end
