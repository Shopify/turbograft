require 'test_helper'

class PagesControllerTest < ActionController::TestCase
  def setup
    request.session[:employee] = { :email => "dummy@example.com" }
  end

  test "GET :show" do
    get :show
    assert_response :success
    assert_select "body > h1", count: 1
  end

  #TODO

  # TODO: test Cookies set_request_method_cookie
  # TODO: test Redirection redirect_via_turbolinks_to
  # TODO: test XDomainBlocker same_origin?
  # TODO: test XDomainBlocker abort_xdomain_redirect
  # TODO: test XHRHeaders _compute_redirect_to_location
  # TODO: test XHRHeaders store_for_turbolinks
  # TODO: test XHRHeaders set_xhr_redirected_to
  # TODO: test XHRHeaders _normalize_redirect_params
  # TODO: test XHRUrlFor included
  # TODO: test XHRUrlFor url_for_with_xhr_referer
end

