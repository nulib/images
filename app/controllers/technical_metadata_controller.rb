class TechnicalMetadataController < ApplicationController

  def show
    @obj = ActiveFedora::Base.find(params[:id], :cast=>true)
    authorize! :view_technical_metadata, @obj
    body = @obj.datastreams[params[:type]].content
puts "rendering: #{body}"
    render :text=> body, :content_type => Mime::XML
  end

end
