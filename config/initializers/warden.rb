Rails.configuration.middleware.use RailsWarden::Manager do |manager|
  manager.default_strategies :password
  manager.failure_app = SessionController
end
RailsWarden.unauthenticated_action = 'new'

# Setup Session Serialization
Warden::Manager.serialize_into_session{ |user|      [user.class, user.id] }
Warden::Manager.serialize_from_session{ |klass, id| klass.find(id)        }

# Strategies  
require COUCH_EXPRESS + '/couch_express/auth/strategies/password'
Warden::Strategies.add(:password) do 
  include CouchExpress::Strategy::Password
end       

require COUCH_EXPRESS + '/couch_express/auth/strategies/remember_me'
Warden::Strategies.add(:remember_me) do 
  include CouchExpress::Strategy::RememberMe
end       