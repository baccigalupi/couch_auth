require COUCH_EXPRESS + '/couch_express/auth/controller/remember_me'

class SessionController < ApplicationController 
  include CouchExpress::ControllerAuth::RememberMe
  
  def new
    if current_user
      redirect_to logged_in_home
    else
      flash[:error] = warden.message unless warden.message.blank?
    end     
  end
  
  def index 
    redirect_to '/login'
  end   
  
  def create 
    authenticate!
    add_remember_token
    redirect_to logged_in_home 
  end
  
  def delete
    forget_me! 
    logout
    redirect_to '/'
  end
  
  # helper methods
  def logged_in_home 
    users_url  # some other url should be used 
    # should be a redirect to saved session location or to users dashboard
  end
        
end # SessionController
