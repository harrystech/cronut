class ApplicationController < ActionController::Base
  protect_from_forgery
  DEFAULT_USERNAME = "admin"
  DEFAULT_PASSWORD = "password"
  DEFAULT_IP_WHITELIST = "127.0.0.1,0.0.0.0"

  before_filter :ip_whitelist
  before_filter :basic_auth

  def basic_auth
    authenticate_or_request_with_http_basic do |username, password|
      expected_username = ENV.fetch("CRONUT_USERNAME", DEFAULT_USERNAME)
      expected_password = ENV.fetch("CRONUT_PASSWORD", DEFAULT_PASSWORD)
      if username != expected_username
        puts "Failed username"
        return false
      end
      if expected_password == password
        @passed_auth=true
        return true
      end
      puts "ERROR: Failed basic auth"
      request_http_basic_authentication
      return false
    end
  end

  def ip_whitelist
    allowed_ips = ENV.fetch("CRONUT_IP_WHITELIST", DEFAULT_IP_WHITELIST).split(",")
    ip = request.headers.fetch("X-Forwarded-For", request.ip)
    if !allowed_ips.include?(ip)
      puts "ERROR: Failed IP check for #{ip}"
      unless ENV.has_key?("CRONUT_IP_WHITELIST")
        puts "You probably need to set CRONUT_IP_WHITELIST env variable"
      end
      return render json: "Unauthorized", status: 401
    end
  end
end
