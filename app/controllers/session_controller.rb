require 'ostruct'
class SessionController < ApplicationController
  
  def new 
    # new.html.erb
  end  
  
  def create 
    authenticate
    redirect_to users_url # some other url should be used
  end
  
  def delete
    logout
    redirect_to '/'
  end    
end
