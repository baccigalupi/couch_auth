SiteOptions = HashWithIndifferentAccess.new({
  :development => {
    :host => 'localhost:3000',
    :emails => {
      :no_reply => 'no_reply@pageboycms.com',
      :info => 'info@pageboycms.com'
    }
  },
  
  :production => {
    :host => 'pageboycms.com', # or whatever
    :emails => {
      :no_reply => 'no_reply@pageboycms.com',
      :info => 'info@pageboycms.com'
    }
  },
  
  :test => {
    :host => 'localhost:3000',
    :emails => {
      :no_reply => 'no_reply@pageboycms.com',
      :info => 'info@pageboycms.com'
    }
  },
  
  :cucumber => {
    :host => 'localhost:3000',
    :emails => {
      :no_reply => 'no_reply@pageboycms.com',
      :info => 'info@pageboycms.com'
    }
  }
})

Site = SiteOptions[RAILS_ENV] 