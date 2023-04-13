class ActiveStorage::BlobsController < ActiveStorage::BaseController
  before_action :authenticate_user!
  include ActiveStorage::SetBlob

  def show
    expires_in ActiveStorage.service_urls_expire_in
    redirect_to @blob.service_url(disposition: params[:disposition])
  end
end
