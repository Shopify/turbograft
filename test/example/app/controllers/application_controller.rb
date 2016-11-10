class ApplicationController < ActionController::Base
  before_action :setup_counters
  protect_from_forgery

  def test
    head :ok
  end

  def unauthenticated
    head :ok
  end

  protected
  def setup_counters
    [:counter_a, :counter_b].each do |counter|
      setup_or_iterate_counter!(counter)
    end
  end

  def setup_or_iterate_counter!(counter)
    session[counter] ||= 0
    session[counter] += 1
  end
end
