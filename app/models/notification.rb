class Notification < ActiveRecord::Base
  belongs_to :job
  attr_accessible :job

  def alert
    raise "ERROR: alert must be defined"
  end
end
