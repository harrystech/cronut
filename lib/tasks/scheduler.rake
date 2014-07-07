desc "This task is called by the Heroku scheduler add-on"
task :check_expired_jobs => :environment do
  puts "Checking expired jobs..."
  Job.check_expired_jobs
  puts "done."
end
