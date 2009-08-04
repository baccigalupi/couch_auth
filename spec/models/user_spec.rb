require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe User do
  before(:each) do
    User.all.each {|doc| doc.destroy }
     
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
      # couchrest is not working as anticipated because the error 
      # is being attached to the method name, not the username field. 
      # I am going to let this fail until they get back to me and say
      # they aren't changing it.
      user_2.should_not be_valid
      user_2.errors.on(:username).should_not be_nil
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
    
    it 'should be valid when the password_confirmation preceeds the password' do 
      user = User.new( {
        :password_confirmation => 'secret',
        :username => 'rughetto',
        :password => 'secret',
        :emails => ['ru_ghetto@rubyghetto.com', 'baccigalupi@gmail.com']
      })
      user.should be_valid
    end    
  end      

  describe 'faux activerecord munges' do 
    # this stuff has been added to couchrest, 
    # so it is here just to ensure forward compatibility
    # rspec, uses Klass.create! when building an model spec
    
    it 'should create!' do
      lambda {
        User.create!( @valid_attributes )
      }.should_not raise_error
    end
    
    it 'create! should save and return the record on success' do
      u = User.create!( @valid_attributes )
      u.should_not be_nil
      u.should_not be_new_record
      u.username.should == 'rughetto'
    end
      
    it 'create! should throw an error on failure to save' do
      @valid_attributes.delete(:username) 
      lambda { User.create!( @valid_attributes ) }.should raise_error
    end   
  end 
  
  describe 'changed?' do
    before(:each) do
      @user = User.new( @valid_attributes )
    end  
    
    it 'should return true when new record' do
      @user.should be_changed
    end  
    
    it 'should return true when record is saved and then an attribute has changed' do
      @user.save
      @user.username = 'gus'
      @user.should be_changed
    end
      
    it 'should return false when record is saved and no attributes have been altered' do
      @user.save
      @user.should_not be_changed
    end
      
    it 'should take a valid attribute key as an argument and return true if that attribute has changed' do
      @user.save
      @user.username = 'gus'
      @user.changed?(:username).should be_true
    end
      
    it 'should take a valid attribute key as an argument and return false in that attribute is the same' do
      @user.save
      @user.changed?(:username).should be_false
    end  
    
    it 'should take an invalid attribute key and return false' do
      @user.save
      @user.changed?(:garbage).should be_false
    end
      
    it 'should not persist an attribute for the method and value of "prev"' do
      @user.save
      @user.username = 'gus'
      @user.changed?
      @user.save
      @user[:prev].should == nil
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
  
end
