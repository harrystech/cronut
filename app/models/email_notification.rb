class EmailNotification < Notification
  validates :value, :presence => true

  #   attr_accessible :value

  def self.model_name
    superclass.model_name
  end

  def alert(job)
    ActionMailer::Base.mail(:from => Rails.application.config.notification_from_email, :to => self.value, :subject => "Job \"#{job.name}\" didn't run", :body => "#{job.name} -  Last ran at: #{job.last_successful_time_str}").deliver!
    return job.next_scheduled_time.to_i.to_s
  end

  def early_alert(job)
    ActionMailer::Base.mail(:from => Rails.application.config.notification_from_email, :to => self.value, :subject => "Job \"#{job.name}\" ran too early", :body => "#{job.name} -  Ran at: #{now_date_str}, Scheduled for: #{job.next_scheduled_time_str}").deliver!
  end

  def recover(job, event_key)
    if event_key
      expired_date_str = Time.at(event_key.to_i).in_time_zone(TIME_ZONE).strftime("%B %-d, %Y %l:%M:%S%P %Z")
      ActionMailer::Base.mail(:from => Rails.application.config.notification_from_email, :to => self.value, :subject => "Recovered: Job \"#{job.name}\" ran late successfully", :body => "#{job.name} -  Ran at: #{now_date_str}, Scheduled for: #{expired_date_str}").deliver!
    end
  end

  private
  def now_date_str
    return Time.now.in_time_zone(TIME_ZONE).strftime("%B %-d, %Y %l:%M:%S%P %Z")
  end
end
