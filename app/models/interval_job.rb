class IntervalJob < Job
  attr_accessible :frequency
  validates :frequency, :presence => true

  def self.model_name
    superclass.model_name
  end

  def calculate_next_scheduled_time!
      self.next_scheduled_time = Time.now + frequency.seconds + extra_time
  end

  def frequency_str
    return Job.time_str(frequency)
  end
end
