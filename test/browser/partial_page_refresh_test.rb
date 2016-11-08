require 'test_helper'
require 'benchmark'

class PartialPageRefreshTest < ActionDispatch::IntegrationTest
  include Capybara::DSL

  setup do
    reset_session!
    visit "/pages/1"
  end

  test "will refresh just parts of the page" do
    random_a = find('#random-number-a').text
    random_b = find('#random-number-b').text

    assert random_a
    assert random_b

    click_link "Go to next page via partial refresh"
    page.assert_text("page 2")
    assert_equal random_a, find('#random-number-a').text
    assert_equal random_b, find('#random-number-b').text
  end

  test "can refresh just one section at a time" do
    random_a = find('#random-number-a').text
    random_b = find('#random-number-b').text

    assert random_a
    assert random_b

    click_button "Refresh Section A"
    page.assert_text("page 1")
    assert_not_equal random_a, find('#random-number-a').text
    assert_equal random_b, find('#random-number-b').text

    random_a = find('#random-number-a').text
    click_button "Refresh Section B"
    page.assert_text("page 1")
    assert_equal random_a, find('#random-number-a').text
    assert_not_equal random_b, find('#random-number-b').text

    random_b = find('#random-number-b').text
    click_button "Refresh Section A and B"
    page.assert_text("page 1")
    assert_not_equal random_a, find('#random-number-a').text
    assert_not_equal random_b, find('#random-number-b').text
  end

  test "when I use an XHR and POST to an endpoint that returns me a 302, I should see the URL reflecting that redirect too" do
    assert page.has_content?("page 1")
    old_location = current_url

    click_button "Post via XHR and see X-XHR-Redirected-To"

    page.assert_text("page 321")

    page.document.synchronize do
      throw "not ready" unless current_url != old_location
    end
  end

  test "data-tg-remote on a link with GET and data-tg-refresh-on-success and status 200" do
    assert page.has_content?("page 1")
    old_location = current_url

    click_link "data-tg-remote GET to response of 200"

    new_location = current_url
    page.assert_no_text("Page 1")
    assert_equal new_location, old_location
  end

  test "data-tg-remote on a link with GET and data-tg-full-refresh-on-success-except and status 200" do
    random_a = find('#random-number-a').text

    assert page.has_content?("page 1")
    old_location = current_url

    click_link "data-tg-remote GET to response of 200 with data-tg-full-refresh-on-success-except"

    new_location = current_url
    page.assert_no_text("Page 1")
    assert_equal random_a, find('#random-number-a').text
    assert_equal new_location, old_location
  end

  test "data-tg-remote on a link with GET and data-tg-refresh-on-error and status 422" do
    assert page.has_content?("page 1")
    old_location = current_url

    click_link "data-tg-remote GET to response of 422"

    new_location = current_url
    page.assert_text("Error 422!")
    assert_equal new_location, old_location
  end

  test "data-tg-remote on a form with post, in status codes: 422 and 200" do
    click_button "Submit data-tg-remote POST"
    assert page.has_content?("Please supply a foo!")

    page.fill_in 'foopost', :with => 'some text'
    click_button "Submit data-tg-remote POST"

    page.assert_no_text("Please supply a foo!")
    assert page.has_content?("Thanks for the foo! We'll consider it.")
  end

  test "data-tg-remote on a form with get" do
    click_button "Submit data-tg-remote GET"
    page.assert_text("Please supply a foo!")

    page.fill_in 'fooget', :with => 'some text'
    click_button "Submit data-tg-remote GET"

    page.assert_no_text("Please supply a foo!")
    assert page.has_content?("We found no results for some text :(")
  end

  test "data-tg-remote on a form with patch" do
    click_button "Submit data-tg-remote PATCH"
    page.assert_text("Thanks, we got your patch.")
  end

  test "data-tg-remote on a form with put" do
    click_button "Submit data-tg-remote PUT"
    page.assert_text("Please supply a foo!")

    page.fill_in 'fooput', :with => 'some text'
    click_button "Submit data-tg-remote PUT"

    page.assert_no_text("Please supply a foo!")
    assert page.has_content?("Thanks, we replaced your foo with a new one.")
  end

  test "data-tg-remote on a form with delete" do
    click_button "Submit data-tg-remote DELETE"
    page.assert_text("Please confirm that you want to delete this foo.")

    page.check 'foodelete'
    click_button "Submit data-tg-remote DELETE"

    page.assert_no_text("Please confirm that you want to delete this foo.")
    assert page.has_content?("Your foo has been destroyed.")
  end
end
