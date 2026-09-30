class NewsController < ApplicationController
  before_action :authenticate_user!
  
  def index
    # Controller for the testing news page
  end
end
