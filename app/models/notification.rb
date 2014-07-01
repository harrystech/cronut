class Notification < ActiveRecord::Base
  has_and_belongs_to_many :jobs
  attr_accessible :name
  validates :name, :presence => true

  def alert(job)
    raise "ERROR: alert must be defined"
  end

  def early_alert(job)
    raise "ERROR: early_alert must be defined"
  end
end
