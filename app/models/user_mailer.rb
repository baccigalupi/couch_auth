class UserMailer < ActionMailer::Base

  default_url_options[:host] = Site[:host]

  def change_password( user, email=nil )
    from       Site[:emails][:no_reply]
    recipients email || user.email
    subject    "Change your password"
    body       :user => user
  end

  def verify_email(user)
    from       Site[:emails][:no_reply]
    recipients user.email
    subject   "Verify your email"
    body      :user => user
  end

end  