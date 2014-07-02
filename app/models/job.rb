class Job < ActiveRecord::Base
  has_and_belongs_to_many :notifications
  attr_accessible :name, :notifications, :notification_ids, :buffer_time

  before_create :create_public_id!, :if => Proc.new{|job| job.public_id.blank?}
  before_save :check_if_pinged_within_buffer_time

  default_scope :order => 'next_scheduled_time'

  validates :name, :presence => true

  def create_public_id!
    public_id = SecureRandom.hex(6).upcase
    collision = Job.find_by_public_id(public_id)

    while !collision.nil?
        public_id = SecureRandom.hex(6).upcase
        collision = Job.find_by_public_id(public_id)
    end

    self.public_id = public_id
  end

  def ping!
    self.last_successful_time = Time.now
    self.save!
  end

  def expire!
    notifications.each { |n|
      begin
        n.alert(self)
      rescue Exception => e
        puts "Exception on alert trigger for #{self.name} - #{n.name}: #{e.inspect}"
      end
    }
    self.save!
  end

  def extra_time
    return (buffer_time ? buffer_time : 0).seconds
  end

  def buffer_time_str
    return buffer_time ? Job.time_str(buffer_time) : "none"
  end

  def last_successful_time_str
    return last_successful_time ? last_successful_time.in_time_zone("Eastern Time (US & Canada)").strftime("%B %-d, %Y %l:%M:%S%P EST") : "never"
  end

  def next_scheduled_time_str
    return next_scheduled_time.in_time_zone("Eastern Time (US & Canada)").strftime("%B %-d, %Y %l:%M:%S%P EST")
  end

  def check_if_pinged_within_buffer_time
    if !buffer_time || !next_scheduled_time || self.next_scheduled_time <= Time.now || (self.last_successful_time && self.last_successful_time + (self.buffer_time * 2).seconds >= self.next_scheduled_time)
      calculate_next_scheduled_time!
    elsif buffer_time && next_scheduled_time && last_successful_time_changed?
      notifications.each { |n|
        n.early_alert(self)
      }
    end
  end

  def calculate_next_scheduled_time!
    raise "ERROR: calculate_next_scheduled_time must be defined"
  end

  def self.check_expired_jobs
    expired_jobs = Job.where("next_scheduled_time < ?", Time.now)
    puts "#{expired_jobs.length} jobs expired"

    expired_jobs.each { |job|
      puts "Job: #{job.name} expired"
      job.expire!
    }
  end

  def self.time_str(seconds)
    if seconds % 2629740 == 0
      num = seconds / 2629740
      unit = "month"
    elsif seconds % 604800 == 0
      num = seconds / 604800
      unit = "week"
    elsif seconds % 86400 == 0
      num = seconds / 604800
      unit = "day"
    elsif seconds % 3600 == 0
      num = seconds / 3600
      unit = "hour"
    elsif seconds % 60 == 0
      num = seconds / 60
      unit = "minute"
    else
      num = seconds
      unit = "second"
    end

    return "#{num} #{unit.pluralize(num)}"
  end
end
