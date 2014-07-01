class Job < ActiveRecord::Base
  has_many :notifications
  attr_accessible :name, :pagerduty, :email

  attr_accessor :pagerduty, :email

  after_initialize :create_public_id!
  after_validation :calculate_next_scheduled_time!

  default_scope :order => 'next_scheduled_time'

  def create_public_id!
    if !public_id.blank?
      return
    end

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
      n.alert
    }
    self.save!
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
end
