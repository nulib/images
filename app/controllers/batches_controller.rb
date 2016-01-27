require 'dil/pid_minter'

class BatchesController < ApplicationController
include DIL::PidMinter

  def new
  end

  def create
    user_email = current_user.email
    Delayed::Job.enqueue CreateMultiresimagesBatchJob.new(params[:job_number], user_email)
    render :create
  end

end
