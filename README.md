the_cronic
==========

Nothing but an open-source scheduling-based dead man's switch server implementation in Rails. Do you have regularly scheduled tasks that need to be executed throughout the day, but not sure if they have been completed or not? the_cronic may be the solution allow you to relax and leave you in a wonderful place.

the_cronic allows you to set a schedule of when expected jobs are to happen using intervals or cron expressions, and notify you if an expected job hasn't run. the_cronic expects each of your jobs to send a POST request (such as using `curl`) to a unique URL and if that has not happened by a certain time, it will notify you. It works out of the box with Heroku along with some simple security features, but it is flexible to be deployed in other ways.

Features
--------
- Monitors scheduled jobs to ensure they run on schedule
- Jobs can be scheduled by a regular interval
- Jobs can be scheduled by a cron expression
- Optionally set a buffer time for a job, where it must be completed by a certain amount of time before or after the expected time
- Notifies if a job is not run by the expected time
- Notifies if a job is ran too early (only when there is a buffer time set)
- Notifies when a job is finally run after the job misses a schedule
- Notification by email
- Integration with [PagerDuty](http://www.pagerduty.com)

Getting Started
------------
Fork the repo and pull it down locally

    $ bundle install
    $ bundle exec rake db:migrate
	$ bundle exec rails s

Open up <http://localhost:3000> in your browser

Setting Up a Scheduler
--------------------
You will need to set up a scheduler in order to continously monitor when jobs as they (may or may not) expire. the_cronic supports using Clockwork or Heroku Scheduler. Clockwork is recommended when you want further granularity, as the Heroku Scheduler can schedule jobs to run only as often as every 10 minutes. By default, the scheduler will run every minute with Clockwork.

###Option 1: Using Clockwork
Start up a new clock dyno that runs:

	$ clockwork lib/clock.rb

###Option 2: Using Heroku Scheduler
For a cheaper (and possibly free) alternative, you can use Heroku Scheduler instead. Keep in mind that the scheduler can only run as often as every 10 minutes, so expired jobs may not be caught as soon as you like. First, add Heroku Scheduler to your app:

	$ heroku addons:add scheduler
Open the Heroku Scheduler dashboard by running:

	$ heroku addons:open scheduler

Click "Add Job...", type in `rake check_expired_jobs`, change frequency to "Every 10 minutes" and click Save.


Configuration
-------------
The default mail configuration uses SMTP with `ActionMailer`. To utilize email notifications, set the following environment variables:

	SMTP_USERNAME: maryjane
	SMTP_PASSWORD: smith
	SMTP_DOMAIN: harrys.com
	SMTP_ADDRESS: smtp.emailprovider.com

Security
--------
The default security is HTTP basic auth, with username `admin` and password
`password`. To set new credentials, set the following environment variables:

    THE_CRONIC_USERNAME: myuser
    THE_CRONIC_PASSWORD: mypass
We also offer an IP address whitelist feature. Set the following environment
variable as a comma-separated list of IP addresses:

    curl -s http://ifconfig.me
    THE_CRONIC_WHITELIST: '10.0.1.2,192.168.1.34'
Additionally, an implementation of API tokens is included for use when a scheduled job is pinging the app (see below). To generate said token, run the script:

	$ script/generate-api-token -n <name_of_token>

You may optionally set a private RSA key to encrypt the `public_id` to uniquely identify each job during each ping. If you do so, make sure when you make your ping requests (see below) to encrypt your `POST` params for `public_id`. Set the following environment variable:

	THE_CRONIC_PRIVATE_KEY: -----BEGIN RSA PRIVATE KEY----- <private_key> -----END RSA PRIVATE KEY-----

Usage
-----
On the_cronic dashboard, you can schedule two types of jobs: interval jobs and cron jobs.

###Interval Jobs
Interval jobs are jobs that occur in regular intervals. These jobs are expected to run once per frequency in seconds, regardless of what the time is on the clock.

**Example:** An interval job with frequency of 600 seconds (10 minutes)

The job is created at 4:10pm, so the next scheduled time is 4:20pm.

If the job does not receive a ping by 4:20pm, notifications are sent.

If a ping is received at 4:16pm, its next schedule time will be 600 seconds from that, which is 4:26pm.


###Cron Jobs
Cron jobs are jobs that are run based on a cron expression.

**Example:** A cron job with the expression `*/10 * * * *` (every 10 minutes on the clock)

The job is created at 4:12pm, the next scheduled time is 4:20pm.

If the job does not receive a ping by 4:20pm, notifications are sent.

If a ping is received at 4:16pm, its next schedule time will be the next calculated time using the cron expression based on the previous scheduled time (4:20pm), which is 4:30pm.

###Buffer Time
Sometimes you may want further granularity of when a job is actually run. For instance, if you have a job that is scheduled to run once a day, it may not be good enough to know just that it ran within that period of time without knowing *when*. The buffer time attribute allows you to specify the time in seconds in which a ping is good as long as it falls within that number of seconds before *or* after the expected schedule time.

**Example:** An interval job with frequency of 600 seconds (10 minutes) with a buffer time of 120 seconds (2 minutes)

The job is created at 4:10pm, so the next scheduled time is 4:22pm, because of the buffer time.

If a ping is received at 4:13pm, an early alert notification is sent and the next scheduled time is unchanged, as it falls outside of the time window when a ping is acceptable.

If a ping is received at 4:19pm, the next scheduled time will be 600 seconds + 120 seconds from that, which is 4:31pm.

**Example:** A cron job with the expression `*/10 * * * *` (every 10 minutes on the clock) with a buffer time of 120 seconds (2 minutes)

The job is created at 4:12pm, so the next scheduled time is 4:22pm, because of the buffer time.

If a ping is received at 4:15pm, an early alert notification is sent and the next scheduled time is unchanged, as it falls outside of the time window when a ping is acceptable.

If a ping is received at 4:19pm, the next scheduled time will be the next calculated time using the cron expression based on the previous scheduled time (4:22pm) plus the buffer time, which is 4:32pm.


###Status
Jobs that have successfully received pings before the previously expected schedule times have the status "Active", while jobs that have not been pinged have the status "Expired." Jobs that are newly created or have their configurations changed and have not been pinged yet carry the status of "Ready."

###Ping
To hook your scheduled job into this app, you would need to make sure it pings the app. To do that, just make sure your job makes a `POST` request to [/ping](http://localhost:3000/ping) with the parameter `public_id` with the value of current Unix epoch time appended with a hypen and the `public_id` of the specified job. You would also need to include the generated API token (see above under **Security**) as an HTTP header with field name `X-THE_CRONIC-API-TOKEN`

**Example:**

	1404863196-<public_id>

###Notifications
The app currently supports notification via email and PagerDuty. You can add as many notification methods as you like through the admin interface. Each job can have multiple notification methods, and each notification method can be associated to multiple jobs. For email notifications, enter your email address in the `value` field. For PagerDuty notifications, you would need to enter the API key in the `value` field.

To get the PagerDuty API key:

1. Log in to [PagerDuty](http://www.pagerduty.com) or create a new account
2. Click on Services
3. Click on "Add New Services"
4. Fill in name and pick an Escalation Policy (you may need to create one if you don't have one already)
5. Select "Use our API directly"
6. Click "Add Service"
7. Copy the key that is next to the "Service API Key" heading

Contributing
------------

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
