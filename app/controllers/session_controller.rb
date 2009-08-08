class SessionController < ApplicationController
  
  def new
    if current_user
      redirect_to logged_in_home
    else
      logger.debug("Warden = #{request.env['warden'].inspect}")
    end     
  end 
  
  def create 
    authenticate!
    redirect_to logged_in_home 
  end
  
  def delete
    # remove remember.cookie
    # remove user.auth['remember_me']
    logout
    redirect_to '/'
  end
  
  # helper methods
  def logged_in_home 
    users_url  # some other url should be used 
    # should be a redirect to saved session location or to users dashboard
  end      
end
