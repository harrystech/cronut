require 'spec_helper'

describe "notifications/new" do
  before(:each) do
    assign(:notification, stub_model(EmailNotification,
      :name => "MyString",
      :value => "MyString"
    ).as_new_record)
  end

  it "renders new notification form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form[action=?][method=?]", notifications_path, "post" do
      assert_select "input#notification_name[name=?]", "notification[name]"
      assert_select "input#notification_value[name=?]", "notification[value]"
    end
  end
end
