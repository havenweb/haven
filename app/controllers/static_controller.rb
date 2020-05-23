class StaticController < ApplicationController
  before_action :authenticate_user!
  before_action :verify_publisher
  def markdown
  end
end
