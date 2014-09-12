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
end
