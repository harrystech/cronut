require 'spec_helper'

describe Notification do
  after(:all) do
    ActiveRecord::Base.connection.reset_pk_sequence!('jobs')
    ActiveRecord::Base.connection.reset_pk_sequence!('notifications')
  end

  it "cannot create object of Notification without type" do
    expect {
      Notification.create!({:name => "Test notification"})
    }.to raise_error(ActiveRecord::StatementInvalid)
  end
end
