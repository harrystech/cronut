require 'clockwork'
include Clockwork

require './config/boot'
require './config/environment'

Clockwork.configure do |config|
  config[:tz] = TIME_ZONE || 'America/New_York'
end

every(1.minute, 'check-expired-jobs') {
  Job.check_expired_jobs
}
