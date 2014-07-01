class IntervalJob < Job
  attr_accessible :frequency
  validates :frequency, :presence => true

  def self.model_name
    superclass.model_name
  end

  def calculate_next_scheduled_time!
    self.next_scheduled_time = Time.now + frequency.seconds
  end

  def frequency_string
    if frequency % 2629740 == 0
      return "#{frequency / 2629740} month(s)"
    end
    if frequency % 604800 == 0
      return "#{frequency / 604800} month(s)"
    end
    if frequency % 86400 == 0
      return "#{frequency / 86400} day(s)"
    end
    if frequency % 3600 == 0
      return "#{frequency / 3600} hour(s)"
    end
    if frequency % 60 == 0
      return "#{frequency / 60} minute(s)"
    end
    return "#{frequency} second(s)"
  end
end
