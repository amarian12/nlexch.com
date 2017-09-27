module Deposits
  module Bankable
    extend ActiveSupport::Concern

    included do
      validates :fund_extra, :fund_uid, :amount, :to_bank, presence: true
      delegate :accounts, to: :channel
    end
  end
end
