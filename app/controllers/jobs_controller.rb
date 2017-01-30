class JobsController < ApplicationController
  API_TOKEN_HEADER = 'X-CRONUT-API-TOKEN'
  before_filter(:only => [:ping]) { |c| c.verify_api_token }
  skip_before_filter :filter_for_ip_whitelist, :only => [:ping]
  skip_before_filter :basic_auth, :only => [:ping]

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
  end

  # POST /jobs
  # POST /jobs.json
  def create
    if params[:job][:type] == "CronJob"
      params[:job].delete(:type)
      params[:job].delete(:frequency)
      @job = CronJob.new(params.require(:job).permit(:name, :notifications, :notification_ids, :buffer_time, :cron_expression))
    elsif params[:job][:type] == "IntervalJob"
      params[:job].delete(:type)
      params[:job].delete(:cron_expression)
      @job = IntervalJob.new(params.require(:job).permit(:name, :notifications, :notification_ids, :buffer_time, :frequency))
    else
      @job = Job.new
      respond_to do |format|
          format.html { render action: "new" }
          format.json { render json: {:error => "Invalid job type"}, status: :unprocessable_entity }
      end
      return
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

    respond_to do |format|
      if @job.update_attributes(job_params)
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
    begin
      str = params[:public_id]
      if Encryptor.enabled?
        if use_base64?
          str = Base64.decode64(str)
        end
        str = Encryptor.decrypt(str)
      end
      array = str.split("-")
      if (array[0].to_i - Time.now.to_i).abs > 30
        puts "Timestamp does not match"
        raise "Timestamp does not match"
      end
      @job = Job.find_by_public_id!(array[1])
    rescue StandardError => e
      puts e.message
      raise ActiveRecord::RecordNotFound.new('Not Found')
    end

    @job.ping!
  end

  def verify_api_token
    token_response = ApiToken.verify_token(request.headers[API_TOKEN_HEADER])
    if !token_response[:success]
      puts "Rejecting invalid API token"
      return render json: token_response[:error], status: 401
    end
  rescue
    puts "Exception verifying API token"
  end

  private

  def use_base64?
    params[:use_base64].to_s == "true"
  end

  def job_params
    params.require(:job).permit(:name, :notifications, {notification_ids: []}, :frequency, :cron_expression, :buffer_time)
  end
end
