require 'spec_helper'

describe BatchUpdateController do
  describe "#index" do
    it "should display a search if q= is provided" do
      get :index, :q=>'searchable'
      response.should be_success
      assigns[:document_list].should be_kind_of Array
    end
  end
end
