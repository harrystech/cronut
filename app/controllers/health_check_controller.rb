class HealthCheckController < ApplicationController
  skip_before_filter :filter_for_ip_whitelist
  skip_before_filter :basic_auth

  def index
    result = HealthCheck.did_health_check_occur?

    if result
      render nothing: true
    else
      render nothing: true, status: 400
    end
  end
end
