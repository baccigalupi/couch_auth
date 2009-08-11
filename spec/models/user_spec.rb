require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe User do
  before(:each) do
    User.delete_all
     
    @valid_attributes = {
      :username => 'rughetto',
      :password => 'secret',
      :password_confirmation => 'secret',
      :emails => ['ru_ghetto@rubyghetto.com', 'baccigalupi@gmail.com']
    }
  end
  
  describe 'validation' do
    it 'should be valid with valid params' do 
      user = User.new(@valid_attributes)
      user.valid?.should == true
    end  
    
    it 'must have a username' do 
      params = @valid_attributes.reject{|key, val| key == :username}
      user = User.new( params )
      user.should_not be_valid
      user.errors.on(:username).should_not be_nil
    end  
    
    it 'username must be a lowercase alhpanumeric string with optional hyphens' do 
      ['there is space', 'Iñtërnâtiônàlizætiøn', 'semicolon;', 
        'quote"', 'tick\'', 'backtick`', 'percent%', 'plus+', "tab\t", "newline\n"].each do |username| 
        user = User.new( @valid_attributes.merge(:username => username ) )
        user.should_not be_valid
        user.errors.on(:username).should_not be_nil
      end    
    end
    
    it 'username should be unique' do
      user = User.create!( @valid_attributes.dup )
      user_2 = User.new( :username => @valid_attributes[:username], 
        :password => 'secret', :password_confirmation => 'secret',
        :emails => ['kane@trajectorset.com']
      )
      user_2.should_not be_valid
      # couchrest is not working as anticipated because the error 
      # is being attached to the method name, not the username field. 
      # So this is commented out until there is some resolution
      # user_2.errors.on(:username).should_not be_nil
    end 
    
    it 'username should be valid on resave' do 
      user = User.create!( @valid_attributes ) 
      user.email = 'kane@trajectorset.com'
      lambda{ user.save! }.should_not raise_error
    end   
      
    it 'must have at least one email' do
      params = @valid_attributes.reject{|key, value| key == :emails}
      user = User.new( params )
      user.should_not be_valid
      user.errors.on(:emails).should_not be_nil
    end
    
    describe 'authentication' do 
      
      # this should move to auth model spec in plugin
      it 'authable?/authenticatable? must be true' do 
        user = User.new( @valid_attributes.dup )
        user.should be_authable 
        user.should be_valid 
        
        @valid_attributes.delete(:password)
        @valid_attributes.delete( :password_confirmation )
        user_2 = User.new( @valid_attributes )
        user_2.should_not be_authable
        user_2.should_not be_valid
      end  
      
      describe 'password' do
        it 'password should not be required' do
          @valid_attributes.delete( :password )
          @valid_attributes.delete( :password_confirmation )
          user = User.new( @valid_attributes )
          user.auth[:new_method] = true
          user.should be_authable
          user.should be_valid
        end  
    
        it 'should require a password confirmation when setting password' do
          @valid_attributes.delete( :password_confirmation )
          user = User.new( @valid_attributes ) 
          user.should_not be_valid
        end  
      
        it 'should be valid when the password_confirmation preceeds the password' do 
          user = User.new( {
            :password_confirmation => 'secret',
            :username => 'rughetto',
            :password => 'secret',
            :emails => ['ru_ghetto@rubyghetto.com', 'baccigalupi@gmail.com']
          })
          user.should be_valid
        end    
      
        it 'password should match confirmation when using password' do 
          user = User.new( {
            :password_confirmation => 'not_secret',
            :username => 'rughetto',
            :password => 'secret',
            :emails => ['ru_ghetto@rubyghetto.com', 'baccigalupi@gmail.com']
          })
          user.should_not be_valid 
        end  
      end  
    end
  end
  
  describe 'authentication' do
    it 'should have an auth attribute' do
      user = User.new
      user.keys.should include('auth')
    end  
    
    describe 'password' do
      describe 'on record create' do
        before(:each) do
          @user = User.create!( @valid_attributes )
        end   
        
        it 'should add a "password" hash to the auth attribute' do 
          @user.auth['password'].should_not be_nil
        end
          
        it 'should add "salt" and "encrypted_password" key/values to the authentication["password"] hash' do 
          @user.auth['password']['salt'].should_not be_nil
          @user.auth['password']['encrypted_password']
        end
      end
      
      describe 'on change' do 
        before(:each) do
          @user = User.create!( @valid_attributes )
        end   
        
        it 'should not save a new encrpted_password if the password is not valid' do 
          pass = @user.auth['password']['encrypted_password'].dup
          @user.password_confirmation = 'something'
          @user.password = 'else'
          @user.auth['password']['encrypted_password'].should == pass
        end
          
        it 'should change the encrypted_password if all is good' do
          pass = @user.auth['password']['encrypted_password'].dup
          @user.password = 'something'
          @user.password_confirmation = 'something'
          @user.auth['password']['encrypted_password'].should_not == pass    
        end  
      end
      
      describe 'instance method #authenticate_by_password' do 
        before(:each) do
          @user = User.create!( @valid_attributes )
        end
          
        it 'should #authenticate_by_password, returning a user' do 
          @user.authenticate_by_password('secret').should == @user
        end 
         
        it 'should return false when #authenticate_by_password gets a bad password' do
          @user.authenticate_by_password('not_secret').should == false
        end  
      end  
        
      describe "class method #authenticate_by_email" do
        before(:each) do
          @user = User.create!( @valid_attributes )
        end  
        
        it 'should return a user when given a valid email and password' do 
          User.authenticate_by_email('ru_ghetto@rubyghetto.com', 'secret').id.should == @user.id
          User.authenticate_by_email('baccigalupi@gmail.com', 'secret').id.should == @user.id
        end
          
        it 'should return nil when user is not found' do
          User.authenticate_by_email('kane@trajectorset.com', 'secret').should == nil
        end
         
        it 'should return false when user is found but password is bad' do 
          User.authenticate_by_email('baccigalupi@gmail.com', 'not secret!').should == false
        end  
      end  
      
      describe "class method #authenticate_by_username" do
        before(:each) do
          @user = User.create!( @valid_attributes )
        end  
        
        it 'should return a user when given a valid username and password' do 
          User.authenticate_by_username( 'rughetto', 'secret' ).id.should == @user.id
        end 
        
        it 'should return nil when user is not found' do 
          User.authenticate_by_username('kane', 'baccigalupi').should == nil
        end 
         
        it 'should return false when user is found but password is bad' do 
          User.authenticate_by_username('rughetto', 'not secret!').should == false
        end  
      end
      
      describe "class method #authenticate_by_password" do
        before(:each) do
          @user = User.create!( @valid_attributes )
        end  
        
        it 'should try to authenticate via username' do
          User.authenticate_by_password( 'rughetto', 'secret' ).id.should == @user.id
        end
          
        it 'should try to authenticate via email' do
          User.authenticate_by_password( 'ru_ghetto@rubyghetto.com', 'secret' ).id.should == @user.id 
          User.authenticate_by_password( 'baccigalupi@gmail.com', 'secret' ).id.should == @user.id
        end
          
        it 'should return nil if user is not found' do
          User.authenticate_by_password('kane@trajectorset.com', 'secret').should == nil
          User.authenticate_by_password('kane', 'secret').should == nil
        end  
        
        it 'should return false if user is found but password is bad' do
          User.authenticate_by_password('ru_ghetto@rubyghetto.com', 'not secret!').should == false
          User.authenticate_by_password('baccigalupi@gmail.com', 'not secret!').should == false
          User.authenticate_by_password('rughetto', 'not secret!').should == false
        end  
      end     
    end  
  end        
  
  describe 'getters and setters' do 
    describe 'names' do
      before(:each) do
        @name_params = @valid_attributes.merge( :name => 'Kane Baccigalupi' )
        @user = User.new( @name_params ) 
      end
      
      it 'should have a name' do
        @user.name.should == 'Kane Baccigalupi'
      end
    
      it 'should have a first name' do
        @user.first_name.should == 'Kane'
      end
    
      it 'should have a last name' do
        @user.last_name.should == 'Baccigalupi'
      end
    
      it 'should be able to set individual name directly' do
        user = User.new
        user.first_name = 'Kane'
        user.first_name.should == 'Kane'
        user.name.should == 'Kane'
        user.last_name = 'Baccigalupi'
        user.last_name.should == 'Baccigalupi'
        user.name.should == 'Kane Baccigalupi'
      end
    end
    
    describe 'emails' do
      before(:each) do
        @user = User.new( @valid_attributes.dup )
      end
      
      it '#email should return the first email in emails' do 
        @user.email.should == 'ru_ghetto@rubyghetto.com'
      end
        
      it '#email should add the passed email to the top of emails' do
        new_email = "kane@trajectorset.com"
        @user.email =  new_email
        @user.emails.should include( new_email ) 
        @user.email.should == new_email
      end 
      
      it '#email should not add a duplicate email to emails array' do
        email = @valid_attributes[:emails].last.dup
        @user.email = email
        @user.emails.size.should == @valid_attributes[:emails].size
      end
        
      it '#email should movie an existing email to the top of emails' do
        email = @valid_attributes[:emails].last.dup
        @user.email = email
        @user.emails.first.should == email
      end
        
      it '#email should invalidate model if email format in not valid' do 
        email = "i'm not valid"
        @user.email = email
        @user.should_not be_valid
        @user.errors.on(:emails).should_not be_nil 
      end  
      
      it '#email should not add email to emails if format is invalid' do
        email = "i'm not valid"
        @user.email = email
        @user.emails.size.should == @valid_attributes[:emails].size
        @user.emails.should_not include( email )
      end
        
      it '#email should invalidate model if email is not unique outside the current record' do
        @user.save
        user = User.new(
          :username => 'rue',
          :password => 'secret',
          :password_confirmation => 'secret',
          :emails => ['kane@trajectorset.com'] 
        ) 
        dup_email = 'baccigalupi@gmail.com'
        user.email = dup_email 
        user.should_not be_valid
        user.errors.on(:emails).should_not be_nil
      end 
        
      it '#email should not add email to email if it is not unique' do
        @user.save
        user = User.new(
          :username => 'rue',
          :password => 'secret',
          :password_confirmation => 'secret',
          :emails => ['kane@trajectorset.com'] 
        ) 
        dup_email = 'baccigalupi@gmail.com'
        user.email = dup_email
        user.emails.should_not include( dup_email )
      end  
      
    end      
  end       
  
  describe 'remembering users' do
    before(:each) do 
      @user = User.new( @valid_attributes )
    end
      
    describe 'remember_me' do
      it 'should set the auth["remember_me"] hash' do
        @user.remember_me
        @user.auth['remember_me'].should_not be_nil
        @user.auth.class.should == Hash
      end
        
      it 'should set the auth["remember_me"]["token"]' do
        @user.remember_me
        @user.auth['remember_me']['token'].should_not be_nil
        @user.auth['remember_me']['token'].should_not be_empty
      end
        
      it 'should set the auth["remember_me"]["expires_at"]' do 
        @user.remember_me
        @user.auth['remember_me']['expires_at'].should_not be_nil
      end
      
      it 'should save the document through when the ! version is called' do
        @user.remember_me!
        user = User.first
        user.auth['remember_me'].should_not be_nil
        user.auth['remember_me']['token'].should_not be_nil
        user.auth['remember_me']['expires_at'].should_not be_nil
      end  
      
      it 'should cast the expires_at portion to and from a Time' do
        @user.remember_me!
        user = User.first
        user.remember_expires_at.should_not be_nil
        user.remember_expires_at.class.should == Time
      end
    end
    
    describe 'forget_me' do
      it 'should clear the auth["remember_me"] hash and related' do
        @user.remember_me
        @user.auth['remember_me'].should_not be_nil
        @user.auth['remember_me']['token'].should_not be_nil
        @user.auth['remember_me']['expires_at'].should_not be_nil 
        @user.forget_me
        @user.auth['remember_me'].should be_nil
      end  
    
      it 'should save the document when the ! version is called' do
        @user.remember_me
        @user.auth['remember_me'].should_not be_nil
        @user.auth['remember_me']['token'].should_not be_nil
        @user.auth['remember_me']['expires_at'].should_not be_nil
        @user.forget_me!
        user = User.first
        user.auth['remember_me'].should be_nil
      end  
    end
    
    describe 'authentication' do
      it 'should not affect authable?, since users need at least one other auth method' do
        user = User.new(:username => 'username', :email => 'email@email.com')
        user.should_not be_authable
        user.remember_me
        user.should_not be_authable
      end
        
      it 'should find users by their auth remember_me tokens' do 
        @user.remember_me!
        @user = User.get(@user.id) # this is necessary because the expires at is a date here and a string saved
        token = @user.auth['remember_me']['token']
        user = User.by_remember_me_token(:key => token).first
        user.should_not be_nil
        user.should == @user
      end
        
      describe 'authenticate_by_remember_me, instance level' do
        it 'should return self if token has not expired' do 
          @user.remember_me!
          @user.authenticate_by_remember_me.should == @user
        end
          
        it 'should return false is the user has expired' do 
          @user.remember_me!(Time.now-3.weeks)
          (@user.auth['remember_me']['expires_at'] < Time.now).should == true  
          @user.authenticate_by_remember_me.should == false
        end  
      end
      
      describe 'authenticate_by_remember_me, class level' do 
        it 'should return the user if found and authenticated' do 
          @user.remember_me!
          user = User.authenticate_by_remember_me( @user.auth['remember_me']['token'] ) 
          user.should_not be_nil
          user.should == User.get(@user.id)
        end
          
        it 'should return nil if user not found via auth key' do
          @user.remember_me # not saved 
          user = User.authenticate_by_remember_me( @user.auth['remember_me']['token'] )
          user.should be_nil
        end
          
        it 'should return false if user is found but token has expired' do 
          @user.remember_me!( Time.now - 3.weeks )
          user = User.authenticate_by_remember_me( @user.auth['remember_me']['token'] )
          user.should == false
        end  
      end   
    end 
  end  

  describe 'temporary token usage' do
    before(:each) do 
      @user = User.new( @valid_attributes )
    end
    
    describe 'setting token' do
      it 'should set the auth["temporary_token"] hash' do
        @user.add_temporary_token
        @user.auth['temporary_token'].should_not be_nil
        @user.auth['temporary_token'].class.should == Hash
      end
        
      it 'should set the auth["temporary_token"]["token"]' do
        @user.add_temporary_token
        @user.auth['temporary_token']['token'].should_not be_nil
        @user.auth['temporary_token']['token'].should_not be_empty
      end
        
      it 'should set the auth["temporary_token"]["expires_at"]' do 
        @user.add_temporary_token
        @user.auth['temporary_token']['expires_at'].should_not be_nil
      end
      
      it 'should save the document through when the ! version is called' do
        @user.add_temporary_token!
        user = User.first
        user.auth['temporary_token'].should_not be_nil
        user.auth['temporary_token']['token'].should_not be_nil
        user.auth['temporary_token']['expires_at'].should_not be_nil
      end  
      
      it 'should cast the expires_at portion to and from a Time' do
        @user.add_temporary_token!
        user = User.first
        user.temporary_token_expires_at.should_not be_nil
        user.temporary_token_expires_at.class.should == Time
      end
    end
    
    describe 'clearing token' do
      it 'should clear the auth["temporary_token"] hash and related' do
        @user.add_temporary_token
        @user.auth['temporary_token'].should_not be_nil
        @user.auth['temporary_token']['token'].should_not be_nil
        @user.auth['temporary_token']['expires_at'].should_not be_nil 
        @user.clear_temporary_token
        @user.auth['temporary_token'].should be_nil
      end  
    
      it 'should save the document when the ! version is called' do
        @user.save
        @user.add_temporary_token
        @user.auth['temporary_token'].should_not be_nil
        @user.auth['temporary_token']['token'].should_not be_nil
        @user.auth['temporary_token']['expires_at'].should_not be_nil
        @user.clear_temporary_token!
        user = User.first
        user.auth['temporary_token'].should be_nil
      end  
    end
    
    describe 'authentication' do
      it 'should not affect authable?, since users need at least one other auth method' do
        user = User.new(:username => 'username', :email => 'email@email.com')
        user.should_not be_authable
        user.add_temporary_token
        user.should_not be_authable
      end
        
      it 'should find users by their auth temporary_token tokens' do 
        @user.add_temporary_token!
        @user = User.get(@user.id) # this is necessary because the expires at is a date here and a string saved
        token = @user.auth['temporary_token']['token']
        user = User.by_temporary_token(:key => token).first
        user.should_not be_nil
        user.should == @user
      end
        
      describe 'authenticate_by_temporary_token, instance level' do
        it 'should return self if token has not expired' do 
          @user.save
          @user.add_temporary_token!
          @user.authenticate_by_temporary_token.should == @user
        end
          
        it 'should return false is the user has expired' do 
          @user.save
          @user.add_temporary_token!(Time.now-3.weeks)
          (@user.auth['temporary_token']['expires_at'] < Time.now).should == true  
          @user.authenticate_by_temporary_token.should == false
        end  
      end
      
      describe 'authenticate_by_temporary_token, class level' do 
        it 'should return the user if found and authenticated' do 
          @user.save
          @user.add_temporary_token!
          user = User.authenticate_by_temporary_token( @user.auth['temporary_token']['token'] ) 
          user.should_not be_nil
          user.should == User.get(@user.id)
        end
          
        it 'should return nil if user not found via auth key' do
          @user.add_temporary_token # not saved 
          user = User.authenticate_by_temporary_token( @user.auth['temporary_token']['token'] )
          user.should be_nil
        end
          
        it 'should return false if user is found but token has expired' do 
          @user.save # verification temp token created for new record ...
          @user.add_temporary_token!( Time.now - 3.weeks ) # now save with expired token
          user = User.authenticate_by_temporary_token( @user.auth['temporary_token']['token'] )
          puts user.inspect
          user.should == false
        end  
      end 
    end 
  end
  
  describe 'lost password!' do
    before(:each) do 
      @user = User.new( @valid_attributes )
    end
    
    it 'should set the temporary_token' do
      @user.lost_password!
      user = User.find( @user.id )
      user.auth['temporary_token'].should_not be_nil
    end
    
    it 'should authenticated by temporary_token afterwards' do 
      @user.lost_password!
      @user.authenticate_by_temporary_token.should == @user
    end  
      
    it 'should send a lost password email' do
      UserMailer.should_receive(:deliver_change_password)
      @user.lost_password!
    end
    
    it 'should send it to the non-primary email if requested' do
      UserMailer.should_receive(:deliver_change_password).with( @user, 'baccigalupi@gmail.com')
      @user.lost_password!('baccigalupi@gmail.com')
    end 
    
    it 'should not send email to an address not related to user' do
      UserMailer.should_receive(:deliver_change_password).with( @user, 'ru_ghetto@rubyghetto.com')
      @user.lost_password!('not_real@gmail.com')
    end     
  end   
  
  describe 'verify email' do
    before(:each) do 
      @user = User.new( @valid_attributes )
    end
     
    it 'on user creation should send email' do 
      UserMailer.should_receive(:deliver_verify_email)
      @user.save
    end
    
    it 'should be unverified initially' do
      @user.save
      @user.should_not be_verified
    end  
    
    it 'should verify' do 
      @user.verify
      @user.should be_verified
    end  
    
    it 'should verify!' do
      @user.verify!
      user = User.get(@user.id)
      user.should be_verified
    end   
  end  

end
