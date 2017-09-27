class AddToBankToDeposits < ActiveRecord::Migration
  def change
    add_column :deposits, :to_bank, :string
  end
end
