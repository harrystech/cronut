class EmailNotification < Notification
  attr_accessible :value
  validates :value, :presence => true

  def self.model_name
    superclass.model_name
  end

  def alert(job)
    ActionMailer::Base.mail(:from => "thecronic@harrys.com", :to => self.value, :subject => "Job \"#{job.name}\" didn't run", :body => "#{job.name} -  Last ran at: #{job.last_successful_time_str}").deliver!
  end

  def early_alert(job)
    ActionMailer::Base.mail(:from => "thecronic@harrys.com", :to => self.value, :subject => "Job \"#{job.name}\" ran too early", :body => "#{job.name} -  Last ran at: #{job.last_successful_time_str}").deliver!
  end
end