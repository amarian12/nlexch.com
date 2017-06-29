class AddFiatPaymentTransactionIdToDeposits < ActiveRecord::Migration
  def change
    add_column :deposits, :fiat_payment_transaction_id, :string
  end
end
