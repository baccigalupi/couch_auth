Rails.configuration.middleware.use RailsWarden::Manager do |manager|
  manager.default_strategies :password
  manager.failure_app = SessionController
end

RailsWarden.default_user_class = User
RailsWarden.unauthenticated_action = 'new'

# Setup Session Serialization
Warden::Manager.serialize_into_session{ |user|      [user.class, user.id] }
Warden::Manager.serialize_from_session{ |klass, id| klass.find(id)        }

# Strategies here
Warden::Strategies.add(:password) do
  def valid?
    params['session'] && 
    params['session']['password'] && 
    (params['session']['username'] || params['session']['email'] || params['session']['login'] ) 
  end
  
  # put this is a module and include across all strategies
  def remember_if_requested!( user )
    if params['session'] && params['session']['remember_me'] == '1'
      # user.remember!
      # cookies.remember_token = user.auth['remember_me']['token'] # domain wide
    end  
  end  
    
  def authenticate!
    login = params['session']['login'] || params['session']['username'] || params['session']['email'] 
    if user = RailsWarden.default_user_class.authenticate_by_password( login, params['session']['password'] )
      success!( user) 
    else
      if ( user == false )
        message = 'Password incorrect'
      else
        message = 'User not found'
      end    
      fail!( message )
    end   
  end
end      