require 'test_helper'
require 'benchmark'

class FullPageRefreshTest < ActionDispatch::IntegrationTest
  include Capybara::DSL

  setup do
    visit "/pages/1"
  end

  test "will strip noscript tags" do
    click_link "Perform a full refresh"
    refute page.has_selector?("noscript") # this test should pass, I think
    refute page.has_content?("Please enable JavaScript")
  end

  test "will replace the title and body" do
    page.execute_script "document.title = 'Something';"
    page.execute_script "$('body').addClass('hot-new-bod');"
    click_link "Perform a full refresh"
    assert_not_equal "Something", page.title
    refute page.has_selector?("body.hot-new-bod")
  end

  test "will execute scripts that do not have data-turbolinks-eval='false'" do
    click_link "Perform a full refresh"
    assert page.has_selector?("div.eval-true")
  end

  test "will not execute scripts that have data-turbolinks-eval='false'" do
    click_link "Perform a full refresh"
    refute page.has_selector?("div.eval-false")
  end

  test "will not keep any refresh-never nodes around" do
    assert page.has_selector?("[refresh-never]")
    click_link "next"
    refute page.has_selector?("[refresh-never]")
  end
end
