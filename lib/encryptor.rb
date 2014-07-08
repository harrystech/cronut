class Encryptor
  class << self
    def encrypt(plain_text)
      OpenSSL::PKey::RSA.new(@@private_key).public_key.public_encrypt(plain_text)
    end

    def decrypt(encrypted_text)
      OpenSSL::PKey::RSA.new(@@private_key).private_decrypt(encrypted_text)
    end

    def public_key
      OpenSSL::PKey::RSA.new(@@private_key).public_key
    end

    def enabled?
      !!ENV['THE_CRONIC_PRIVATE_KEY']
    end

    @@private_key = ENV['THE_CRONIC_PRIVATE_KEY']
  end
end