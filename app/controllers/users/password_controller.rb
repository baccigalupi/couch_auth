module Users 
  class PasswordController 
    
    # form that asks user for email
    def new
    end  
    
    # retrieves user by email, creates temporary token, sends email instruction
    def create
      user = User.by_email(params[:email])
      user.lost_password!(params[:email]) # creates temp token and sends email
      flash[:notice] = 'You should receive an email with next steps for changing you password withing five minutes or so. Please follow the instructions.'
      redirect_to "/"
    end  
    
    # shows user change password form
    def edit
      authenticate(:temporary_token) 
      if current_user # authenticated
        # show edit password form 
      else # bad or expired token
        flash[:error] = warden.message unless warden.message.blank?
        render :new 
      end    
    end
    
    # change user the password
    def update
      current_user.password = params[:user][:password]
      current_user.password_confirmation = params[:user][:password_confirmation]
      if current_user.valid?
        current_user.save
        flash[:notice] = 'Your password has been changed'
        redirect_back
      else
        render :edit 
      end   
    end
        
  end # PasswordController
end # Users    