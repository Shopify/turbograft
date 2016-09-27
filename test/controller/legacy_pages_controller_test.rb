require 'test_helper'

class LegacyPagesControllerTest < ActionController::TestCase
  test "set_request_method_cookie does not set cookie for GET requests" do
    get :show
    refute response.headers.key?('Set-Cookie')
  end

  test "set_request_method_cookie sets request method for non GET requests" do
    post :show
    assert_equal 'POST', cookies[:request_method]
  end

  test "redirect_via_turbolinks_to sets response body and status" do
    get :index
    assert_response :ok
    assert_equal "Turbolinks.visit('http://test.host/legacy_pages/1');", response.body
    assert_equal Mime::JS, response.content_type
  end

  test "abort_xdomain_redirect returns 403 when cross origin" do
    @request.headers["X-XHR-Referer"] = 'http://www.example.com'
    get :new
    assert_response :forbidden
  end

  test "_compute_redirect_to_location sets redirect_to for turbolinks" do
    @request.headers["X-XHR-Referer"] = 'http://test.host'
    get :index
    assert_response :ok
    assert_equal "http://test.host/legacy_pages/1", session[:_turbolinks_redirect_to]
  end

  test "_compute_redirect_to_location sets redirect_to for turbolinks only if request referrer is set" do
    get :index
    assert_response :ok
    assert_nil session[:_turbolinks_redirect_to]
  end

  test "XHR GET for the page matching the redirect will set X-XHR-Redirected-To" do
    session[:_turbolinks_redirect_to] = 'http://test.host/legacy_pages/321'
    get :show, params: {id: 321}, xhr: true
    assert_equal 'http://test.host/legacy_pages/321', response.headers['X-XHR-Redirected-To']
  end

  test "XHR GET for a page not matching the redirect will not set X-XHR-Redirected-To" do
    session[:_turbolinks_redirect_to] = 'http://test.host/legacy_pages/321'
    get :show, params: {id: 11}, xhr: true
    assert_nil response.headers['X-XHR-Redirected-To']
  end
end
