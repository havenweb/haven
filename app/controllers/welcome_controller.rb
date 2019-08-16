class WelcomeController < ApplicationController
  def index
    redirect_to posts_url
  end
end
