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

  test "when I use an XHR and POST to an endpoint that returns me a 302, I should see the URL reflecting that redirect too" do
    assert page.has_content?("page 1")
    old_location = current_url

    click_button "Post via XHR and see X-XHR-Redirected-To"

    assert page.has_content?("page 321")

    page.document.synchronize do
      throw "not ready" unless current_url != old_location
    end
  end

  test "data-tg-remote on a link with GET and data-tg-refresh-on-success and status 200" do
    assert page.has_content?("page 1")
    old_location = current_url

    click_link "data-tg-remote GET to response of 200"

    new_location = current_url
    refute page.has_content?("Page 1")
    assert_equal new_location, old_location
  end

  test "data-tg-remote on a link with GET and data-tg-full-refresh-on-success-except and status 200" do
    random_a = find('#random-number-a').text

    assert page.has_content?("page 1")
    old_location = current_url

    click_link "data-tg-remote GET to response of 200 with data-tg-full-refresh-on-success-except"

    new_location = current_url
    refute page.has_content?("Page 1")
    assert_equal random_a, find('#random-number-a').text
    assert_equal new_location, old_location
  end

  test "data-tg-remote on a link with GET and data-tg-refresh-on-error and status 422" do
    assert page.has_content?("page 1")
    old_location = current_url

    click_link "data-tg-remote GET to response of 422"

    new_location = current_url
    assert page.has_content?("Error 422!")
    assert_equal new_location, old_location
  end

  test "data-tg-remote on a form with post, in status codes: 422 and 200" do
    click_button "Submit data-tg-remote POST"
    assert page.has_content?("Please supply a foo!")

    page.fill_in 'foopost', :with => 'some text'
    click_button "Submit data-tg-remote POST"

    refute page.has_content?("Please supply a foo!")
    assert page.has_content?("Thanks for the foo! We'll consider it.")
  end

  test "data-tg-remote on a form with get" do
    click_button "Submit data-tg-remote GET"
    assert page.has_content?("Please supply a foo!")

    page.fill_in 'fooget', :with => 'some text'
    click_button "Submit data-tg-remote GET"

    refute page.has_content?("Please supply a foo!")
    assert page.has_content?("We found no results for some text :(")
  end

  test "data-tg-remote on a form with patch" do
    click_button "Submit data-tg-remote PATCH"
    assert page.has_content?("Thanks, we got your patch.")
  end

  test "data-tg-remote on a form with put" do
    click_button "Submit data-tg-remote PUT"
    assert page.has_content?("Please supply a foo!")

    page.fill_in 'fooput', :with => 'some text'
    click_button "Submit data-tg-remote PUT"

    refute page.has_content?("Please supply a foo!")
    assert page.has_content?("Thanks, we replaced your foo with a new one.")
  end

  test "data-tg-remote on a form with delete" do
    click_button "Submit data-tg-remote DELETE"
    assert page.has_content?("Please confirm that you want to delete this foo.")

    page.check 'foodelete'
    click_button "Submit data-tg-remote DELETE"

    refute page.has_content?("Please confirm that you want to delete this foo.")
    assert page.has_content?("Your foo has been destroyed.")
  end

  test "tg-remote refreshing the same URL will not push onto history stack" do
    visit "/pages/2"

    expect_sections_a_and_b_differ do
      click_link "Perform a partial page refresh of the current page"
    end

    expect_sections_a_and_b_differ do
      click_link "Perform a partial page refresh of the current page"
    end

    page.evaluate_script('window.history.back()')

    assert page.has_content?("page 1")

  end

  def expect_sections_a_and_b_differ(&block)
    assert random_a = find('#random-number-a').text
    assert random_b = find('#random-number-b').text

    yield

    assert_not_equal random_a, find('#random-number-a').text
    assert_not_equal random_b, find('#random-number-b').text
  end
end
