ActionController::Routing::Routes.draw do |map|
  # authentication stuff 
  map.resources :session
  map.connect '/login',  :controller => 'session', :action => 'new'
  map.connect '/logout', :controller => 'session', :action => 'destroy'
  
  map.resources :users do |users|
    users.resource :reset_password, :only => [:new, :create, :edit, :update], :controller => 'users/password'
    users.resource :verify_email,   :only => [:update], :controller => 'users/verify'
  end

end
