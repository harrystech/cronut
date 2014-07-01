class Encryptor
  class << self
    def encrypt(plain_text)
      OpenSSL::PKey::RSA.new(get_private_key).public_key.public_encrypt(plain_text)
    end

    def decrypt(encrypted_text)
      OpenSSL::PKey::RSA.new(get_private_key).private_decrypt(encrypted_text)
    end

    def public_key
      OpenSSL::PKey::RSA.new(get_private_key).public_key
    end

    private
    def get_private_key
      ENV['THE_CRONIC_PRIVATE_KEY'] || OpenSSL::PKey::RSA.generate
    end
  end
end