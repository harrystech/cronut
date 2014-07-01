require 'spec_helper'

describe "jobs/index" do
  before(:each) do
    assign(:jobs, [
      stub_model(IntervalJob, {:name => "Test job", :frequency => 3600, :next_scheduled_time => Time.now}),
      stub_model(IntervalJob, {:name => "Test job", :frequency => 3600, :next_scheduled_time => Time.now})
    ])
  end

  it "renders a list of jobs" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
  end
end
