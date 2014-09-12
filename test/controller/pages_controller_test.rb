require 'test_helper'

class PagesControllerTest < ActionController::TestCase
  test "set_request_method_cookie sets request method" do
    get :show
    assert_equal 'GET', cookies[:request_method]
  end

  test "redirect_via_turbolinks_to sets response body and status" do
    get :index
    assert_response :ok
    assert_equal "Turbolinks.visit('http://test.host/pages/1');", response.body
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
    assert_equal "http://test.host/pages/1", session[:_turbolinks_redirect_to]
  end

  test "set_xhr_redirected_to clears session and sets X-XHR-Redirected-To" do
    get :index, {}, {_turbolinks_redirect_to: 'http://test.host/expected'}
    assert_response :ok
    assert_nil session[:_turbolinks_redirect_to]
    assert_equal 'http://test.host/expected', response.headers['X-XHR-Redirected-To']
  end
end
