# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_saasy_manager_session',
  :secret      => '2022d3e8947e699961216eafb85caf2676f44db352a87b0c90193295f2a6ad65e3d1080d6142443b65c238be5b14899fc3d9fbdb8441155526a8cccb16ae48ad'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
