require "rails"
require "active_support"

require "turbograft/version"
require "turbograft/xhr_headers"
require "turbograft/xhr_url_for"
require "turbograft/cookies"
require "turbograft/x_domain_blocker"
require "turbograft/redirection"

module TurboGraft
  class Config
    cattr_accessor :controllers
    self.controllers = ["ActionController::Base"]
  end

  class Engine < ::Rails::Engine

    initializer :turbograft do |config|
      ActiveSupport.on_load(:action_controller) do
        Config.controllers.each do |klass|
          klass.constantize.class_eval do
            include XHRHeaders, Cookies, XDomainBlocker, Redirection
            before_action :set_xhr_redirected_to, :set_request_method_cookie
            after_action :abort_xdomain_redirect
          end
        end

        ActionDispatch::Request.class_eval do
          def referer
            self.headers['X-XHR-Referer'] || super
          end
          alias referrer referer
        end
      end

      ActiveSupport.on_load(:action_view) do
        (ActionView::RoutingUrlFor rescue ActionView::Helpers::UrlHelper).prepend(XHRUrlFor)
      end
    end
  end
end
