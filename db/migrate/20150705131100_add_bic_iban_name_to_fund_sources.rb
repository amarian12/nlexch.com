class AddBicIbanNameToFundSources < ActiveRecord::Migration
  def change
    add_column :fund_sources, :account_name, :string
  end
end
