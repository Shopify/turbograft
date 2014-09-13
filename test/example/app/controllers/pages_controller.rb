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

  def html_with_noscript; end

  def new
    render json: "{}", location: 'http://www.notexample.com'
  end
end
