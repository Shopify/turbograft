require 'test_helper'
require 'benchmark'

class PageRequestTest < ActionDispatch::IntegrationTest
  include Capybara

  test "visit page" do
    visit "/pages/1"
    20.times { click_link "next" }
    click_link "beginning"
  end
end