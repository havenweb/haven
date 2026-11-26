# config/initializers/verify_secret_key_base.rb
#
# Refuse to boot in production if the app is missing a strong SECRET_KEY_BASE
# or is still using the publicly leaked 2019 secret_key_base / master.key.

if Rails.env.production? && ENV["SECRET_KEY_BASE_DUMMY"].blank?
  require "digest"

  COMPROMISED_SECRET_KEY_BASE_SHA256 = "02a37e75cd80fbac771cdf5cf3f6e84e21056e367adf9bab63303802dce345e5"
  COMPROMISED_MASTER_KEY_SHA256      = "ede3bd8ce753b3d0904143730a391316b79ecdbf98e1a76f1d8f028cc065ac6f"

  secret_key_base = Rails.application.secret_key_base.to_s.strip

  if secret_key_base.empty? || secret_key_base.bytesize < 32
    raise <<~MSG
      Refusing to boot: SECRET_KEY_BASE is missing or too short.
      Generate a unique key with `bin/rails secret` and set it via the SECRET_KEY_BASE environment variable.
    MSG
  end

  if Digest::SHA256.hexdigest(secret_key_base) == COMPROMISED_SECRET_KEY_BASE_SHA256
    raise <<~MSG
      Refusing to boot: SECRET_KEY_BASE matches the publicly compromised key from Haven's Git history.
      Delete config/master.key and config/credentials.yml.enc, generate a fresh key with `bin/rails secret`,
      and set SECRET_KEY_BASE before restarting.
    MSG
  end

  master_key_file = Rails.root.join("config/master.key")
  master_key_candidates = [
    ENV["RAILS_MASTER_KEY"],
    (master_key_file.read if master_key_file.exist?)
  ].compact.map(&:strip)

  if master_key_candidates.any? { |k| Digest::SHA256.hexdigest(k) == COMPROMISED_MASTER_KEY_SHA256 }
    raise <<~MSG
      Refusing to boot: the publicly compromised config/master.key or RAILS_MASTER_KEY is still present.
      Delete config/master.key and config/credentials.yml.enc (and unset RAILS_MASTER_KEY) before restarting.
    MSG
  end
end
