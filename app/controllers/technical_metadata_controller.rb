class TechnicalMetadataController < ApplicationController

  def show
    authorize! :show, :technical_metadata
    body = fetch_resource(params[:type])
    respond_to do |format|
      format.xml { render :xml=> body }
      format.text {render :text=>body }
    end
  end

  def fetch_resource(type)
    url = resource_url(type)
    logger.info "Proxying to #{url}"
    result = Net::HTTP.get_response( URI.parse(url))
    return result.body
  end

  def resource_url(type)
    client = ActiveFedora::Base.connection_for_pid(params[:id]).client
    uri = URI.parse client.url+"/objects/#{params[:id]}/datastreams/#{type}/content"
    uri.user = client.user
    uri.password = client.password
    uri.to_s
  end
end