class PagesController < ApplicationController
  def show
    @id = params[:id]
    @next_id = @id.to_i + 1

    if params[:turbo]
      @link_opts = {}
      @url_opts = {:turbo => true}
    else
      @url_opts = {}
      @link_opts = { :"data-no-turbolink" => true}
    end
  end
end
