module TurboGraft
  # Intercepts calls to _compute_redirect_to_location (used by redirect_to) for two purposes.
  #
  # 1. Corrects the behavior of redirect_to with the :back option by using the X-XHR-Referer
  # request header instead of the standard Referer request header.
  #
  # 2. Stores the return value (the redirect target url) to persist through to the redirect
  # request, where it will be used to set the X-XHR-Redirected-To response header.  The
  # Turbolinks script will detect the header and use replaceState to reflect the redirected
  # url.
  module XHRHeaders
    extend ActiveSupport::Concern

    included do
      alias_method_chain :_compute_redirect_to_location, :xhr_referer
    end

    private

    if Rails::VERSION::MAJOR == 4 && Rails::VERSION::MINOR > 1
      def _compute_redirect_to_location_with_xhr_referer(request, options)
        session[:_turbolinks_redirect_to] =
          if options == :back && request.headers["X-XHR-Referer"]
            _compute_redirect_to_location_without_xhr_referer(request, request.headers["X-XHR-Referer"])
          else
            _compute_redirect_to_location_without_xhr_referer(request, options)
          end
      end
    else
      def _compute_redirect_to_location_with_xhr_referer(options)
        session[:_turbolinks_redirect_to] =
          if options == :back && request.headers["X-XHR-Referer"]
            _compute_redirect_to_location_without_xhr_referer(request.headers["X-XHR-Referer"])
          else
            _compute_redirect_to_location_without_xhr_referer(options)
          end
      end
    end

    def set_xhr_redirected_to
      if session[:_turbolinks_redirect_to]
        response.headers['X-XHR-Redirected-To'] = session.delete :_turbolinks_redirect_to
      end
    end
  end
end
