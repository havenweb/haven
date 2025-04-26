class StaticController < ApplicationController
  before_action :authenticate_user!
## Demo should expose these endpoints to all logged-in users
#  before_action :verify_publisher
#  before_action :verify_admin, except:[:themes]
  def markdown
  end
  def themes
  end
end
