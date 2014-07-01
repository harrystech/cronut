class CronJob < Job
  attr_accessible :cron_expression, :buffer_time
  validates :cron_expression, :buffer_time, :presence => true
  validate :validate_cron_expression

  def calculate_next_scheduled_time!
    cron = CronParser.new(cron_expression)

    now = Time.now

    # Calculate to see if the last successful time was close enough to count as hitting the next cycle
    if self.last_successful_time && self.last_successful_time + (self.buffer_time * 2).seconds >= self.next_scheduled_time
      now = self.next_scheduled_time + 1.seconds
    end
    self.next_scheduled_time = cron.next(now) + buffer_time.seconds
  end

  def self.model_name
    superclass.model_name
  end

  private

  def validate_cron_expression
    values = cron_expression.split

    if values.length < 5 || values.length > 6
      self.errors.add(:cron_expression, "invalid value")
    else
      attempt_to_parse = CronParser.new(cron_expression)
      attempt_to_parse.next(Time.now)
    end
  end
end
