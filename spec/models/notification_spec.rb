require 'spec_helper'

describe Notification do
  it "cannot create object of Notification without type" do
    expect {
      Notification.create!({:name => "Test notification"})
    }.to raise_error(ActiveRecord::StatementInvalid)
  end
end
