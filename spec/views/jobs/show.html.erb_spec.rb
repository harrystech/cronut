require 'spec_helper'

describe "jobs/show" do
  before(:each) do
    @job = assign(:job, stub_model(IntervalJob, {:name => "Test job", :frequency => 3600, :next_scheduled_time => Time.now}))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
  end
end
