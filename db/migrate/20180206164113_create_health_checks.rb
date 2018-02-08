class CreateHealthChecks < ActiveRecord::Migration
  def self.up
    create_table :health_checks do |t|

      t.datetime :time_of_last_check, null: false
      t.timestamps null: false
    end

    HealthCheck.create(time_of_last_check: Time.now)
  end

  def self.down
    drop_table :health_checks
  end
end
