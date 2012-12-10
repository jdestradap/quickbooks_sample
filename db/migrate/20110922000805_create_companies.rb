class CreateCompanies < ActiveRecord::Migration
  def self.up
    create_table :companies do |t|
      t.string :name
      t.string :realm
      t.references :owner
      t.string :intuit_access_token
      t.string :intuit_access_secret
      t.boolean :is_qbo

      t.timestamps
    end
  end

  def self.down
    drop_table :companies
  end
end
