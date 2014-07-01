class EmailNotification < Notification
  attr_accessible :email
  validates :email, :presence => true

  def alert
    ActionMailer::Base.mail(:from => "thecronic@harrys.com", :to => "#{self.email_address}", :subject => "Job \"#{job.name}\" didn't run", :body => "#{job.name} -  Last ran at: #{job.last_successful_time ? job.last_successful_time.in_time_zone("Eastern Time (US & Canada)").strftime("%B %-d, %Y %l:%M:%S%P EST") : "never"}").deliver!
  end

  def to_s
  	return email
  end
end