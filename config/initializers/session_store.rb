# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_couch_auth_session',
  :secret      => '6ec49e5276978b4603c40e569e5a1993b346ead2de4a1ee30f3ca5f97a228c73d104ebeccbe7c8a7964db960d29aec1327b4d4893a490c3bddfc61100dc56096'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
