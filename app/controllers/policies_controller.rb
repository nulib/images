class PoliciesController < ApplicationController
  load_and_authorize_resource :class=>AdminPolicy

  def new
    @page_title = 'Create a policy'
  end

  def edit
    @page_title = 'Edit policy'
  end
end
