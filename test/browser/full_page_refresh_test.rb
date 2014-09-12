require 'test_helper'
require 'benchmark'

class FullPageRefreshTest < ActionDispatch::IntegrationTest
  include Capybara::DSL

  test "will strip noscript tags" do
    visit "/pages/1"
    click_link "Perform a full refresh"
    refute page.has_content?("Please enable JavaScript")
  end

  test "will replace the title and body" do
    visit "/pages/1"
    click_link "Perform a full refresh"
    assert_equal "Sample static HTML", page.title
    assert page.has_selector?("body.hot-new-bod")
  end

  test "will execute scripts that do not have data-turbolinks-eval='false'" do
    visit "/pages/1"
    click_link "Perform a full refresh"
    assert page.has_content?("Hi there, from a script!")
  end
end
