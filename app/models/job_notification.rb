class JobNotification < ActiveRecord::Base
  belongs_to :job
  belongs_to :notification


  def alert!
    begin
      self.last_event_key = notification.alert(job)
      save!
    rescue Exception => e
      puts "Exception on alert trigger for #{job.name} - #{notification.name}: #{e.inspect}"
    end
  end

  def early_alert
    begin
      notification.early_alert(job)
    rescue Exception => e
      puts "Exception on early alert trigger for #{job.name} - #{notification.name}: #{e.inspect}"
    end
  end

  def recover!
    begin
      notification.recover(job, last_event_key)
    rescue Exception => e
      puts "Exception on recover alert trigger for #{job.name} - #{notification.name}: #{e.inspect}"
    end
    self.last_event_key = nil
    save!
  end
end