require 'spec_helper'

describe "notifications/index" do
  before(:each) do
    assign(:notifications, [
      stub_model(Notification,
        :name => "Name",
        :type => "Type",
        :value => "Value"
      ),
      stub_model(Notification,
        :name => "Name",
        :type => "Type",
        :value => "Value"
      )
    ])
  end

  it "renders a list of notifications" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Name".to_s, :count => 2
    assert_select "tr>td", :text => "Type".to_s, :count => 2
    assert_select "tr>td", :text => "Value".to_s, :count => 2
  end
end
