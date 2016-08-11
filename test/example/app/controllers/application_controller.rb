class ApplicationController < ActionController::Base
  protect_from_forgery

  def test
    head :ok
  end

  def unauthenticated
    head :ok
  end
end
