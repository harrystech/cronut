class CronJob < Job
  attr_accessible :cron_expression
  validates :cron_expression, :presence => true
  validate :validate_cron_expression

  def self.model_name
    superclass.model_name
  end

  def calculate_next_scheduled_time!
    now = Time.now

    # Calculate to see if the last successful time was close enough to count as hitting the next cycle
    if (!buffer_time && self.last_successful_time_changed?) || buffer_time && self.last_successful_time && (self.last_successful_time + (self.buffer_time * 2).seconds >= self.next_scheduled_time && self.next_scheduled_time >= Time.now)
      now = self.next_scheduled_time.in_time_zone("Eastern Time (US & Canada)") + 1.seconds
    end
    self.next_scheduled_time = Rufus::Scheduler.parse(cron_expression).next_time(now) + extra_time
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
end
