class PoliciesController < ApplicationController
  load_and_authorize_resource :class=>AdminPolicy

  def new
  end

  def edit
  end
end
