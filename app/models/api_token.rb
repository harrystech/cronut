class ApiToken < ActiveRecord::Base
  attr_accessible :name, :token
  validates :name, :token, :presence => true

  def self.verify_token(token_in)
    if token_in.blank?
      LOGGER.warn "Empty token given."
      return {
        :success => false,
        :error => "Empty token given."
      }
    end

    token = ApiToken.find_by_token(token_in)
    if token.nil?
      LOGGER.warn "Token #{token_in} not found."
      return {
        :success => false,
        :error => "Invalid token."
      }
    end

    # All good
    LOGGER.info "Token #{token.token} allowed in types #{allowed_types.join(', ')}."
    return { :success => true }
  end
end
