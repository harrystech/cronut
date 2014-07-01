class EmailNotification < Notification
  attr_accessible :email
  validates :email, :presence => true

  def alert
    ActionMailer::Base.mail(:from => "thecronic@harrys.com", :to => self.email, :subject => "Job \"#{job.name}\" didn't run", :body => "#{job.name} -  Last ran at: #{job.last_successful_time_str}").deliver!
  end

  def to_s
  	return email
  end
end