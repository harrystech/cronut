class AddStatusToJobs < ActiveRecord::Migration
  def change
    add_column :jobs, :status, :string, :null => false, default: "READY"
  end
end
