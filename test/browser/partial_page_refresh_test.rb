require 'test_helper'
require 'benchmark'

class PartialPageRefreshTest < ActionDispatch::IntegrationTest
  include Capybara::DSL

  setup do
    visit "/pages/1"
  end

  test "will refresh just parts of the page" do
    random_a = find('#random-number-a').text
    random_b = find('#random-number-b').text

    assert random_a
    assert random_b

    click_link "Go to next page via partial refresh"
    assert page.has_content?("page 2")
    assert_equal random_a, find('#random-number-a').text
    assert_equal random_b, find('#random-number-b').text
  end

  test "can refresh just one section at a time" do
    random_a = find('#random-number-a').text
    random_b = find('#random-number-b').text

    assert random_a
    assert random_b

    click_button "Refresh Section A"
    assert page.has_content?("page 1")
    assert_not_equal random_a, find('#random-number-a').text
    assert_equal random_b, find('#random-number-b').text

    random_a = find('#random-number-a').text
    click_button "Refresh Section B"
    assert page.has_content?("page 1")
    assert_equal random_a, find('#random-number-a').text
    assert_not_equal random_b, find('#random-number-b').text

    random_b = find('#random-number-b').text
    click_button "Refresh Section A and B"
    assert page.has_content?("page 1")
    assert_not_equal random_a, find('#random-number-a').text
    assert_not_equal random_b, find('#random-number-b').text
  end

  test "partial-graft helper works" do
    random_a = find('#random-number-a').text
    random_b = find('#random-number-b').text
    click_button "Partial Graft Helper: A and B"
    assert_not_equal random_a, find('#random-number-a').text
    assert_not_equal random_b, find('#random-number-b').text
  end

  test "when I use an XHR and POST to an endpoint that returns me a 302, I should see the URL reflecting that redirect too" do
    assert page.has_content?("page 1")
    old_location = current_url

    click_button "Post via XHR and see X-XHR-Redirected-To"

    new_location = current_url
    assert page.has_content?("page 321")
    assert_not_equal new_location, old_location
  end

  test "remote-method on a link with GET and refresh-on-success and status 200" do
    assert page.has_content?("page 1")
    old_location = current_url

    click_link "remote-method GET to response of 200"

    new_location = current_url
    refute page.has_content?("Page 1")
    assert_equal new_location, old_location
  end

  test "remote-method on a link with GET and refresh-on-error and status 422" do
    assert page.has_content?("page 1")
    old_location = current_url

    click_link "remote-method GET to response of 422"

    new_location = current_url
    assert page.has_content?("Error 422!")
    assert_equal new_location, old_location
  end
end
