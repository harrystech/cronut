class HealthCheck < ActiveRecord::Base
  THRESHOLD = 2.minutes

  def self.did_health_check_occur?
    time_difference = Time.current - HealthCheck.last.time_of_last_check

    time_difference < THRESHOLD
  end
end
