class PagesController < ApplicationController
  def show
    @id = params[:id]
    @next_id = @id.to_i + 1
  end
end
