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
    redirect_to page_path(321)
  end

  def error_500
    render text: "Error 500!", status: 500
  end

  def error_404
    render html: "Error 404!", status: 404
  end

  def error_422
    render "error_422", status: 422
  end

  def error_422_with_show
    @id = 1
    @next_id = 2

    render :show, status: 422
  end

  def html_with_noscript; end

  def submit_foo
    if params[:foo].blank?
      render '_missing_foo', status: 422
    else
      render '_thanks_for_all_the_foo', status: 200, layout: false # it's not necessary to render a full response, and you may prefer not to
    end
  end

  def new
    render json: "{}", location: 'http://www.notexample.com'
  end
end
