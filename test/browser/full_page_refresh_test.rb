require 'test_helper'
require 'benchmark'

class FullPageRefreshTest < ActionDispatch::IntegrationTest
  include Capybara::DSL

  setup do
    visit "/pages/1"
  end

  test "will strip noscript tags" do
    click_link "Perform a full navigation to learn more"
    refute page.has_selector?("noscript") # this test should pass, I think
    refute page.has_content?("Please enable JavaScript")
  end

  test "will replace the title and body" do
    page.execute_script "document.title = 'Something';"
    page.execute_script "$('body').addClass('hot-new-bod');"
    click_link "Perform a full navigation to learn more"
    assert_not_equal "Something", page.title
    refute page.has_selector?("body.hot-new-bod")
  end

  test "will execute scripts that do not have data-turbolinks-eval='false'" do
    click_link "Perform a full navigation to learn more"
    assert page.has_selector?("div.eval-true")
  end

  test "will not execute scripts that have data-turbolinks-eval='false'" do
    click_link "Perform a full navigation to learn more"
    refute page.has_selector?("div.eval-false")
  end

  test "will not keep any refresh-never nodes around" do
    assert page.has_selector?("[refresh-never]")
    click_link "next"
    refute page.has_selector?("[refresh-never]")
  end

  test "going to a URL that will error 500, and hitting the browser back button, we see the correct page (and not the 500)" do
    click_link "I will throw an error 500"
    assert_not_equal "Sample Turbograft Application", page.title
    page.evaluate_script('window.history.back()')
    assert_equal "Sample Turbograft Application", page.title
  end

  test "going to a URL that will error 404, and hitting the browser back button, we see the correct page (and not the 404)" do
    click_link "I will throw an error 404"
    assert_not_equal "Sample Turbograft Application", page.title
    page.evaluate_script('window.history.back()')
    assert_equal "Sample Turbograft Application", page.title
  end

  test "tg-static preserves client-side state of innards on partial refresh, and replaces contents on full refresh" do
    page.fill_in 'badgeinput', :with => 'tg-static innards'
    click_link "Perform a full page refresh"
    assert_equal "tg-static innards", find_field("badgeinput").value
    click_link "Perform a partial page refresh and refresh the navigation section"
    assert_equal "", find_field("badgeinput").value
  end

  test "always-refresh will always refresh the annotated nodes, regardless of refresh type" do
    page.fill_in 'badgeinput2', :with => 'some innards'
    click_link "Perform a full page refresh"
    assert_equal "", find_field("badgeinput2").value

    page.fill_in 'badgeinput2', :with => 'some innards'
    click_link "Perform a partial page refresh and refresh the navigation section"
    assert_equal "", find_field("badgeinput2").value
  end
end
