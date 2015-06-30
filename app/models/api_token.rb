class ApiToken < ActiveRecord::Base

  validates :name, :token, :presence => true

  def self.verify_token(token_in)
    if token_in.blank?
      puts "Empty token given."
      return {
        :success => false,
        :error => "Empty token given."
      }
    end

    token = ApiToken.find_by_token(token_in)
    if token.nil?
      puts "Token #{token_in} not found."
      return {
        :success => false,
        :error => "Invalid token."
      }
    end

    # All good
    puts "Token #{token.token} allowed."
    return { :success => true }
  end
end
