class ImagesController < ApplicationController
  before_action :authenticate_user!, :set_blob, :set_host
  protect_from_forgery with: :exception

  def show
    expires_in ActiveStorage::Blob.service.url_expires_in
    redirect_to @blob.service_url(disposition: params[:disposition])
  end

  def show_variant
    expires_in ActiveStorage::Blob.service.url_expires_in
    variant = @blob.variant(combine_options:{thumbnail: "1600", quality: '65%', interlace: 'plane', auto_orient: true}).processed
    redirect_to variant.service_url(disposition: params[:disposition])
  end

  private
    def set_blob
      image = Image.find(params[:image_id])
      @blob = image.blob_blob
    rescue ActiveSupport::MessageVerifier::InvalidSignature
      head :not_found
    end

    def set_host
      ActiveStorage::Current.host = request.base_url
    end
end
