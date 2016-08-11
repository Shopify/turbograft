class ApplicationController < ActionController::Base
  protect_from_forgery

  skip_before_filter :authenticate, :only => :unauthenticated

  def test
    head :ok
  end

  def unauthenticated
    head :ok
  end
end
