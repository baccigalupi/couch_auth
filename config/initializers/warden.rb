Rails.configuration.middleware.use RailsWarden::Manager do |manager|
  manager.default_strategies :password
  manager.failure_app = SessionController
end

# set up warden default user class at some point

# Setup Session Serialization
Warden::Manager.serialize_into_session{ |user|      [user.class, user.id] }
Warden::Manager.serialize_from_session{ |klass, id| klass.find(id)        }

# Strategies here
Warden::Strategies.add(:password) do
  def valid?
    params[:session] && 
    params[:session][:password] && 
    (params[:session][:username] || params[:session][:email] || params[:session][:login] ) 
  end
    
  def authenticate!
    login = params[:session][:login] || params[:session][:username] || params[:session][:email] 
    # switch this to use the Warden user at some point
    if user = User.authenticate_by_password( login, params[:session][:password] )
      success!( user) 
    else
      message = (user == false) ? 'Password incorrect' : 'User not found'
      fail!( message )
    end   
  end
end      