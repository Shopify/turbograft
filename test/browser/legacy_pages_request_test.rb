require 'test_helper'
require 'benchmark'

class LegacyPagesPageRequestTest < ActionDispatch::IntegrationTest
  include Capybara::DSL
  include Capybara::Node::Matchers

  test "turbolinks works" do

    visit "/legacy_pages/1"
    tracking_token = find(:css, "meta[name='tracking-token']", visible: false)[:content]

    click_link "next"
    assert_match tracking_token, find(:css, "meta[name='tracking-token']", visible: false)[:content]
  end

  test "url_for_with_xhr_referer :back hack" do
    visit "/legacy_pages/1"
    assert_equal 'javascript:history.back()', find_link('back')[:href]

    click_link "next"
    assert_match /legacy_pages\/1/, find_link('back')[:href]
  end
end
