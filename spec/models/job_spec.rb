require 'spec_helper'

describe Job do
  after(:each) do
    Timecop.return
  end

  after(:all) do
    ActiveRecord::Base.connection.reset_pk_sequence!('jobs')
    ActiveRecord::Base.connection.reset_pk_sequence!('notifications')
  end

  it "cannot create object of Job without type" do
    expect {
      Job.create!({:name => "Test job"})
    }.to raise_error
  end

  describe "#last_successful_time_str" do
    it "returns the last scheduled time in the preferred time zone" do
      stub_const("TIME_ZONE", "America/Los_Angeles")

      job = IntervalJob.new
      job.last_successful_time = Time.utc(2014, 8, 7, 12)

      job.last_successful_time_str.should eq("August 7, 2014  5:00:00am PDT")
    end
  end

  describe "#next_scheduled_time_str" do
    it "returns the next scheduled time in the preferred time zone" do
      stub_const("TIME_ZONE", "America/Los_Angeles")

      job = IntervalJob.new
      job.next_scheduled_time = Time.utc(2014, 8, 7, 12)

      job.next_scheduled_time_str.should eq("August 7, 2014  5:00:00am PDT")
    end
  end

  describe "IntervalJobs" do
    describe "without buffer" do
      before(:each) do
        @start_time = Time.now
        @job = IntervalJob.create!({:name => "Test IntervalJob", :frequency => 600})
      end

      after(:each) do
        @job.destroy
      end

      it "initiates job's values" do
        @job.next_scheduled_time.to_i.should eq (@start_time + 600.seconds).to_i
        @job.last_successful_time.should be_nil
        @job.public_id.should_not be_nil
        @job.status.should eq "READY"
      end

      it "pinging postpones next scheduled time" do
        Timecop.travel(1.minute)
        ping_time = Time.now
        @job.ping!
        @job.next_scheduled_time.to_i.should eq (ping_time + 600.seconds).to_i
        @job.last_successful_time.to_i.should eq ping_time.to_i
        @job.status.should eq "ACTIVE"
      end

      it "expiring postpones next scheduled time" do
        Timecop.travel(10.minutes)
        expire_time = Time.now
        @job.expire!
        @job.next_scheduled_time.to_i.should eq (expire_time + 600.seconds).to_i
        @job.last_successful_time.should be_nil
        @job.status.should eq "EXPIRED"
      end

      it "expires" do
        Timecop.travel(10.minutes)
        expire_time = Time.now
        Job.check_expired_jobs
        @job.reload
        @job.next_scheduled_time.to_i.should >= (expire_time + 600.seconds).to_i
        @job.last_successful_time.should be_nil
        @job.status.should eq "EXPIRED"
      end

      it "expires and alerts notifications" do
        notification = PagerdutyNotification.create!({:name => "Test notification", :value => "dummy value"})
        notification.stub(:alert)
        notification.stub(:recover)
        @job.notifications << notification
        @job.save!
        Timecop.travel(10.minutes)
        notification.should_receive(:alert)
        notification.should_not_receive(:recover)
        @job.expire!
      end

      it "expires and recovers" do
        notification = PagerdutyNotification.create!({:name => "Test notification", :value => "dummy value"})
        notification.stub(:alert)
        notification.stub(:recover)
        @job.notifications << notification
        @job.save!
        Timecop.travel(10.minutes)
        @job.expire!
        Timecop.travel(1.minutes)
        notification.should_not_receive(:alert)
        notification.should_receive(:recover)
        @job.ping!
      end

      it "change settings resets status and next scheduled time" do
        Timecop.travel(10.minutes)
        expire_time = Time.now
        @job.expire!
        @job.next_scheduled_time.to_i.should eq (expire_time + 600.seconds).to_i
        @job.last_successful_time.should be_nil
        @job.status.should eq "EXPIRED"
        @job.frequency = 500
        change_time = Time.now
        @job.save!
        @job.reload
        @job.next_scheduled_time.to_i.should eq (change_time + 500.seconds).to_i
        @job.status.should eq "READY"
      end
    end

    describe "with buffer" do
      before(:each) do
        @start_time = Time.now
        @job = IntervalJob.create!({:name => "Test IntervalJob", :frequency => 600, :buffer_time => 60})
      end

      after(:each) do
        @job.destroy
      end

      it "initiates job's values" do
        @job.next_scheduled_time.to_i.should eq (@start_time + 660.seconds).to_i
        @job.last_successful_time.should be_nil
        @job.public_id.should_not be_nil
        @job.status.should eq "READY"
      end

      it "pinging outside of buffer does not postpones next scheduled time" do
        Timecop.travel(1.minute)
        ping_time = Time.now
        @job.ping!
        @job.next_scheduled_time.to_i.should eq (@start_time + 660.seconds).to_i
        @job.last_successful_time.to_i.should eq ping_time.to_i
        @job.status.should eq "ACTIVE"
      end

      it "pinging within buffer postpones next scheduled time" do
        Timecop.travel(9.minutes)
        ping_time = Time.now
        @job.ping!
        @job.next_scheduled_time.to_i.should eq (ping_time + 660.seconds).to_i
        @job.last_successful_time.to_i.should eq ping_time.to_i
        @job.status.should eq "ACTIVE"
      end

      it "expiring postpones next scheduled time" do
        Timecop.travel(11.minutes)
        expire_time = Time.now
        @job.expire!
        @job.next_scheduled_time.to_i.should eq (expire_time + 660.seconds).to_i
        @job.last_successful_time.should be_nil
        @job.status.should eq "EXPIRED"
      end

      it "expires" do
        Timecop.travel(11.minutes)
        expire_time = Time.now
        Job.check_expired_jobs
        @job.reload
        @job.next_scheduled_time.to_i.should >= (expire_time + 660.seconds).to_i
        @job.last_successful_time.should be_nil
        @job.status.should eq "EXPIRED"
      end

      it "expires and alerts notifications" do
        notification = PagerdutyNotification.create!({:name => "Test notification", :value => "dummy value"})
        notification.stub(:alert)
        notification.stub(:recover)
        @job.notifications << notification
        @job.save!
        Timecop.travel(11.minutes)
        notification.should_receive(:alert)
        notification.should_not_receive(:recover)
        @job.expire!
      end

      it "sends early alert if pinged too early" do
        notification = PagerdutyNotification.create!({:name => "Test notification", :value => "dummy value"})
        notification.stub(:alert)
        notification.stub(:early_alert)
        notification.stub(:recover)
        @job.notifications << notification
        @job.save!
        Timecop.travel(1.minute)
        notification.should_receive(:early_alert)
        notification.should_not_receive(:recover)
        @job.ping!
        @job.status.should eq "ACTIVE"
      end

      it "does not send early alert if job is already late" do
        notification = PagerdutyNotification.create!({:name => "Test notification", :value => "dummy value"})
        notification.stub(:alert)
        notification.stub(:early_alert)
        notification.stub(:recover)
        @job.notifications << notification
        @job.save!
        Timecop.travel(1.minute)
        @job.ping!
        Timecop.travel(10.minutes)
        notification.should_receive(:alert)
        @job.expire!
        Timecop.travel(2.minutes)
        # Job already expired, we shouldn't get another notification that this late ping is early
        notification.should_not_receive(:early_alert)
        notification.should_receive(:recover)
        @job.ping!
      end

      it "sends early alert if job is expired, late ping happened and the next ping was early" do
        notification = PagerdutyNotification.create!({:name => "Test notification", :value => "dummy value"})
        notification.stub(:alert)
        notification.stub(:early_alert)
        @job.notifications << notification
        @job.save!
        Timecop.travel(1.minute)
        @job.ping!
        Timecop.travel(10.minutes)
        @job.expire!
        Timecop.travel(2.minutes)
        @job.ping!
        Timecop.travel(1.minute)
        # We should get an early alert now, though
        notification.should_receive(:early_alert)
        @job.ping!
      end

      it "change settings resets status and next scheduled time" do
        Timecop.travel(11.minutes)
        expire_time = Time.now
        @job.expire!
        @job.next_scheduled_time.to_i.should eq (expire_time + 660.seconds).to_i
        @job.last_successful_time.should be_nil
        @job.status.should eq "EXPIRED"
        @job.frequency = 500
        change_time = Time.now
        @job.save!
        @job.reload
        @job.next_scheduled_time.to_i.should eq (change_time + 560.seconds).to_i
        @job.status.should eq "READY"
      end
    end
  end

  describe "CronJob" do
    describe "without buffer" do
      before(:each) do
        Timecop.travel(Time.at((Time.now.to_f / 600).floor * 600 + 1)) # round to nearest 10 mins
        @start_time = Time.now
        @next_time = Time.at((Time.now.to_f / 600).ceil * 600)
        @job = CronJob.create!({:name => "Test CronJob", :cron_expression => "*/10 * * * *"}) # every 10 mins
      end

      after(:each) do
        @job.destroy
      end

      it "initiates job's values" do
        @job.next_scheduled_time.to_i.should eq @next_time.to_i
        @job.last_successful_time.should be_nil
        @job.public_id.should_not be_nil
        @job.status.should eq "READY"
      end

      it "pinging postpones next scheduled time" do
        Timecop.travel(1.minute)
        ping_time = Time.now
        @job.ping!
        @job.next_scheduled_time.to_i.should eq (@next_time + 600.seconds).to_i
        @job.last_successful_time.to_i.should eq ping_time.to_i
        @job.status.should eq "ACTIVE"
      end

      it "expiring postpones next scheduled time" do
        Timecop.travel(10.minutes)
        @job.expire!
        @job.next_scheduled_time.to_i.should eq (@next_time + 600.seconds).to_i
        @job.last_successful_time.should be_nil
        @job.status.should eq "EXPIRED"
      end

      it "expires" do
        Timecop.travel(11.minutes)
        Job.check_expired_jobs
        @job.reload
        @job.next_scheduled_time.to_i.should eq (@next_time + 600.seconds).to_i
        @job.last_successful_time.should be_nil
        @job.status.should eq "EXPIRED"
      end

      it "expires and alerts notifications" do
        notification = PagerdutyNotification.create!({:name => "Test notification", :value => "dummy value"})
        notification.stub(:alert)
        notification.stub(:recover)
        @job.notifications << notification
        @job.save!
        Timecop.travel(10.minutes)
        notification.should_receive(:alert)
        notification.should_not_receive(:recover)
        @job.expire!
      end

      it "expires and recovers" do
        notification = PagerdutyNotification.create!({:name => "Test notification", :value => "dummy value"})
        notification.stub(:alert)
        notification.stub(:recover)
        @job.notifications << notification
        @job.save!
        Timecop.travel(10.minutes)
        @job.expire!
        Timecop.travel(1.minutes)
        notification.should_not_receive(:alert)
        notification.should_receive(:recover)
        @job.ping!
      end

      it "change settings resets status and next scheduled time" do
        Timecop.travel(10.minutes)
        @job.expire!
        @job.next_scheduled_time.to_i.should eq (@next_time + 600.seconds).to_i
        @job.last_successful_time.should be_nil
        @job.status.should eq "EXPIRED"
        @job.cron_expression = "*/5 * * * *"
        @job.save!
        @job.reload
        @job.next_scheduled_time.to_i.should eq (@next_time + 300.seconds).to_i
        @job.status.should eq "READY"
      end
    end

    describe "with buffer" do
      before(:each) do
        Timecop.travel(Time.at((Time.now.to_f / 600).floor * 600 + 1)) # round to nearest 10 mins
        @start_time = Time.now
        @next_time = Time.at((Time.now.to_f / 600).ceil * 600) + 60.seconds
        @job = CronJob.create!({:name => "Test CronJob", :cron_expression => "*/10 * * * *", :buffer_time => 60}) # every 10 mins
      end

      after(:each) do
        @job.destroy
      end

      it "initiates job's values" do
        @job.next_scheduled_time.to_i.should eq @next_time.to_i
        @job.last_successful_time.should be_nil
        @job.public_id.should_not be_nil
        @job.status.should eq "READY"
      end

      it "pinging outside of buffer does not postpones next scheduled time" do
        Timecop.travel(1.minute)
        ping_time = Time.now
        @job.ping!
        @job.next_scheduled_time.to_i.should eq @next_time.to_i
        @job.last_successful_time.to_i.should eq ping_time.to_i
        @job.status.should eq "ACTIVE"
      end

      it "pinging within buffer postpones next scheduled time" do
        Timecop.travel(9.minutes)
        ping_time = Time.now
        @job.ping!
        @job.next_scheduled_time.to_i.should eq (@next_time + 600.seconds).to_i
        @job.last_successful_time.to_i.should eq ping_time.to_i
        @job.status.should eq "ACTIVE"
      end

      it "expiring postpones next scheduled time" do
        Timecop.travel(11.minutes)
        expire_time = Time.now
        @job.expire!
        @job.next_scheduled_time.to_i.should eq (@next_time + 600.seconds).to_i
        @job.last_successful_time.should be_nil
        @job.status.should eq "EXPIRED"
      end

      it "expires" do
        Timecop.travel(11.minutes)
        expire_time = Time.now
        Job.check_expired_jobs
        @job.reload
        @job.next_scheduled_time.to_i.should eq (@next_time + 600.seconds).to_i
        @job.last_successful_time.should be_nil
        @job.status.should eq "EXPIRED"
      end

      it "expires and alerts notifications" do
        notification = PagerdutyNotification.create!({:name => "Test notification", :value => "dummy value"})
        notification.stub(:alert)
        notification.stub(:recover)
        @job.notifications << notification
        @job.save!
        Timecop.travel(11.minutes)
        notification.should_receive(:alert)
        notification.should_not_receive(:recover)
        @job.expire!
      end

      it "sends early alert if pinged too early" do
        notification = PagerdutyNotification.create!({:name => "Test notification", :value => "dummy value"})
        notification.stub(:alert)
        notification.stub(:early_alert)
        notification.stub(:recover)
        @job.notifications << notification
        @job.save!
        Timecop.travel(1.minute)
        notification.should_receive(:early_alert)
        notification.should_not_receive(:recover)
        @job.ping!
        @job.status.should eq "ACTIVE"
      end

      it "does not send early alert if job is already late" do
        notification = PagerdutyNotification.create!({:name => "Test notification", :value => "dummy value"})
        notification.stub(:alert)
        notification.stub(:early_alert)
        notification.stub(:recover)
        @job.notifications << notification
        @job.save!
        Timecop.travel(1.minute)
        @job.ping!
        Timecop.travel(10.minutes)
        notification.should_receive(:alert)
        @job.expire!
        Timecop.travel(2.minutes)
        # Job already expired, we shouldn't get another notification that this late ping is early
        notification.should_not_receive(:early_alert)
        notification.should_receive(:recover)
        @job.ping!
      end

      it "sends early alert if job is expired, late ping happened and the next ping was early" do
        notification = PagerdutyNotification.create!({:name => "Test notification", :value => "dummy value"})
        notification.stub(:alert)
        notification.stub(:early_alert)
        notification.stub(:recover)
        @job.notifications << notification
        @job.save!
        Timecop.travel(1.minute)
        @job.ping!
        Timecop.travel(10.minutes)
        @job.expire!
        Timecop.travel(2.minutes)
        @job.ping!
        Timecop.travel(1.minute)
        # We should get an early alert now, though
        notification.should_receive(:early_alert)
        notification.should_not_receive(:recover)
        @job.ping!
      end

      it "change settings resets status and next scheduled time" do
        Timecop.travel(11.minutes)
        expire_time = Time.now
        @job.expire!
        @job.next_scheduled_time.to_i.should eq (@next_time + 600.seconds).to_i
        @job.last_successful_time.should be_nil
        @job.status.should eq "EXPIRED"
        @job.cron_expression = "*/5 * * * *"
        @job.save!
        @job.reload
        @job.next_scheduled_time.to_i.should eq (@next_time + 300.seconds).to_i
        @job.status.should eq "READY"
      end
    end
  end
end
