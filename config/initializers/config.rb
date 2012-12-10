AppConfig = YAML.load_file("#{Rails.root}/config/config.yml")[Rails.env]

require 'openid'
require 'openid/extensions/sreg'
require 'openid/extensions/pape'
require 'openid/store/filesystem'

require 'intuit'
