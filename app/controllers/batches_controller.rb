require 'dil/pid_minter'

class BatchesController < ApplicationController
include DIL::PidMinter

  def new
  end

  def create
    #throw the whole thing in a background job
    Delayed::Job.enqueue CreateMultiresimagesBatchJob.new(params[:job_number])
    render :create
  end

end
