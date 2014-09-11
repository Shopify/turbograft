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
    assert page.has_content? "Page 2"
    assert_equal random_a, find('#random-number-a').text
    assert_equal random_b, find('#random-number-b').text
  end

  test "can refresh just one section at a time" do
    random_a = find('#random-number-a').text
    random_b = find('#random-number-b').text

    assert random_a
    assert random_b

    click_button "Refresh Section A"
    assert page.has_content? "Page 1"
    assert_not_equal random_a, find('#random-number-a').text
    assert_equal random_b, find('#random-number-b').text

    random_a = find('#random-number-a').text
    click_button "Refresh Section B"
    assert page.has_content? "Page 1"
    assert_equal random_a, find('#random-number-a').text
    assert_not_equal random_b, find('#random-number-b').text

    random_b = find('#random-number-b').text
    click_button "Refresh Section A and B"
    assert page.has_content? "Page 1"
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
end
