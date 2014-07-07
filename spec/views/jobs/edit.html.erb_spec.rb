require 'spec_helper'

describe "jobs/edit" do
  before(:each) do
    @job = assign(:job, stub_model(IntervalJob, {:name => "Test job", :frequency => 3600, :next_scheduled_time => Time.now}))
  end

  it "renders the edit job form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form[action=?][method=?]", job_path(@job), "post" do
    end
  end
end
