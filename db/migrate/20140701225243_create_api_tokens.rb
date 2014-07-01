class CreateApiTokens < ActiveRecord::Migration
  def change
    create_table :api_tokens do |t|
      t.string :name
      t.string :token

      t.timestamps
    end
    add_index :api_tokens, :name, :unique => true
    add_index :api_tokens, :token, :unique => true
  end
end
