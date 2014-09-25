class PagesController < ApplicationController
  skip_before_action :verify_authenticity_token

  def index
    @id = 1
    redirect_via_turbolinks_to page_path(@id)
  end

  def show
    @id = params[:id]
    @next_id = @id.to_i + 1
  end

  def redirect_to_somewhere_else_after_POST
    redirect_to page_path(1)
  end

  def error_500
    render text: "Error 500!", status: 500
  end

  def error_404
    render text: "Error 404!", status: 404
  end

  def html_with_noscript; end

  def new
    render json: "{}", location: 'http://www.notexample.com'
  end
end
