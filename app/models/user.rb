class User < ActiveRecord::Base
  acts_as_authentic do |c|
    crypto_provider = Authlogic::CryptoProviders::BCrypt
  end

  has_many :companies, :foreign_key => "owner_id"

  def name
    [first_name, last_name].join(" ")
  end

end
