class CronJob < Job
  validates :cron_expression, :presence => true
  validate :validate_cron_expression

  def self.model_name
    superclass.model_name
  end

  private

  def validate_cron_expression
    values = cron_expression.split

    if values.length < 5 || values.length > 6
      self.errors.add(:cron_expression, "invalid value")
    else
      begin
        attempt_to_parse = Rufus::Scheduler.parse(cron_expression)
      rescue Exception => e
        self.errors.add(:cron_expression, "not a valid cronline")
      end
    end
  end

  def set_next_scheduled_time!
    # Calculate to see if the last successful time was close enough to count as hitting the next cycle
    if (!buffer_time && self.last_successful_time_changed?) || buffer_time && self.last_successful_time && (self.last_successful_time + (self.buffer_time * 2).seconds >= self.next_scheduled_time && self.next_scheduled_time >= Time.now)
      self.next_scheduled_time = calculate_next_scheduled_time(self.next_scheduled_time.in_time_zone(TIME_ZONE) + 1.seconds)
      return
    end
    super
  end

  def calculate_next_scheduled_time(now = Time.now)
    return Rufus::Scheduler.parse(cron_expression).next_time(now) + extra_time
  end
end
