# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

require COUCH_EXPRESS + '/couch_express/auth/controller/general'

class ApplicationController < ActionController::Base 
  include CouchExpress::ControllerAuth
  
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  # Scrub sensitive parameters from your log
  filter_parameter_logging :password, :password_confirmation
  
  # makes sure there is a current user
  before_filter :auth_with_remember_me
  def auth_with_remember_me 
    authenticate(:remember_me) unless session && sesssion['user']
  end  

end
