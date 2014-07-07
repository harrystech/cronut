require 'spec_helper'

describe "jobs/new" do
  before(:each) do
    assign(:job, stub_model(IntervalJob, {:name => "Test job", :frequency => 3600, :next_scheduled_time => Time.now}).as_new_record)
  end

  it "renders new job form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form[action=?][method=?]", jobs_path, "post" do
    end
  end
end
