require 'test_helper'
require 'benchmark'

class PageRequestTest < ActionDispatch::IntegrationTest
  include Capybara::DSL
  include Capybara::Node::Matchers

  test "url_for_with_xhr_referer :back hack" do
    visit "/pages/1"
    assert_equal 'javascript:history.back()', find_link('Back Link')[:href]

    click_link "next"
    assert_match /pages\/1/, find_link('Back Link')[:href]
  end
end
