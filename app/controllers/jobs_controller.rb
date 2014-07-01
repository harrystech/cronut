class JobsController < ApplicationController
  # GET /jobs
  # GET /jobs.json
  def index
    @jobs = Job.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @jobs }
    end
  end

  # GET /jobs/1
  # GET /jobs/1.json
  def show
    @job = Job.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @job }
    end
  end

  # GET /jobs/new
  # GET /jobs/new.json
  def new
    @job = Job.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @job }
    end
  end

  # GET /jobs/1/edit
  def edit
    @job = Job.find(params[:id])

    @job.pagerduty = @job.notifications.any? { |n| n.is_a?(PagerdutyNotification)}

    n = @job.notifications.find {|n| n.is_a?(EmailNotification) }
    @job.email = n.presence && n.email
  end

  # POST /jobs
  # POST /jobs.json
  def create
    if params[:job][:type] == "CronJob"
      params[:job].delete(:type)
      params[:job].delete(:frequency)
      @job = CronJob.new(params[:job])
    elsif params[:job][:type] == "IntervalJob"
      params[:job].delete(:type)
      params[:job].delete(:cron_expression)
      params[:job].delete(:buffer_time)
      @job = IntervalJob.new(params[:job])
    else
      @job = Job.new
      respond_to do |format|
          format.html { render action: "new" }
          format.json { render json: {:error => "Invalid job type"}, status: :unprocessable_entity }
      end
      return
    end
    
    if params[:job][:email].presence
      @job.notifications << EmailNotification.new({:email => params[:job][:email]})
    end

    if params[:job][:pagerduty] == "1"
      @job.notifications << PagerdutyNotification.new
    end

    respond_to do |format|
      if @job.save
        format.html { redirect_to @job, notice: 'Job was successfully created.' }
        format.json { render json: @job, status: :created, location: @job }
      else
        format.html { render action: "new" }
        format.json { render json: @job.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /jobs/1
  # PUT /jobs/1.json
  def update
    @job = Job.find(params[:id])

    email_notification = @job.notifications.find {|n| n.is_a?(EmailNotification) }
    if params[:job][:email].presence
      if !email_notification
        email_notification = EmailNotification.new({:job => @job})
      end
      email_notification.email = params[:job][:email]
      email_notification.save!
    else
      if email_notification
        email_notification.destroy
      end
    end

    pd_notification = @job.notifications.find {|n| n.is_a?(PagerdutyNotification) }
    if params[:job][:pagerduty] == "1"
      if !pd_notification
        PagerdutyNotification.create!({:job => @job})
      end
    elsif pd_notification
      pd_notification.destroy
    end

    respond_to do |format|
      if @job.update_attributes(params[:job])
        format.html { redirect_to @job, notice: 'Job was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @job.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /jobs/1
  # DELETE /jobs/1.json
  def destroy
    @job = Job.find(params[:id])
    @job.destroy

    respond_to do |format|
      format.html { redirect_to jobs_url }
      format.json { head :no_content }
    end
  end

  def ping
    @job = Job.find_by_public_id(params[:public_id])

    if !@job
      raise ActionController::RoutingError.new('Not Found')
    end

    @job.ping!
  end
end