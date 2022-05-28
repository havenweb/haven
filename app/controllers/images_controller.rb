class ImagesController < ApplicationController
  before_action :verify_auth!, :set_blob, :set_host
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
    def verify_auth!
      basic_auth_user = params[:u]
      credential = params[:c]
      if basic_auth_user.nil? || credential.nil?
        authenticate_user!
      else
        filename = params[:filename] + "." + params[:format]
        user = User.find_by(basic_auth_username: basic_auth_user)
        image_key = user.image_password
        hmac = OpenSSL::HMAC.hexdigest("SHA256", image_key, filename)
        unless hmac == credential
          raise ActiveRecord::RecordNotFound
        end
      end
    end

    def set_blob
      image = Image.find(params[:image_id])
      request_filename = params[:filename]
      @blob = image.blob_blob
      request_filename = params[:filename]
      blob_filename = @blob.filename.base
      unless (request_filename == blob_filename)
        @blob = nil
        head :not_found
      end
    rescue ActiveSupport::MessageVerifier::InvalidSignature
      head :not_found
    end

    def set_host
      ActiveStorage::Current.host = request.base_url
    end
end
