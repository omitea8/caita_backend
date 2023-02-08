require_relative "boot"

require "rails/all"

Bundler.require(*Rails.groups)

module CaitaBackend
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0
    
    config.api_only = true

    # cookieを使うためのmiddlewareの有効化
    config.middleware.use ActionDispatch::Cookies
    config.middleware.use ActionDispatch::Session::CookieStore, key: '_your_app_session'
    
  end
end
