module Private

  require '/home/albert/.rbenv/versions/2.2.1/lib/ruby/gems/2.2.0/gems/mollie-api-ruby-1.1.3/lib/Mollie/API/Client.rb'
  #require 'lib/Mollie/API/Client.rb'

  class FundsController < BaseController
    layout 'funds'

    before_action :auth_activated!
    before_action :auth_verified!
    before_action :two_factor_activated!

    def index
      @deposit_channels = DepositChannel.all
      @withdraw_channels = WithdrawChannel.all
      @currencies = Currency.all.sort
      @deposits = current_user.deposits
      @accounts = current_user.accounts.enabled
      @withdraws = current_user.withdraws
      @fund_sources = current_user.fund_sources
      @banks = Bank.all

      setup_mollie

      gon.jbuilder
    end

    def gen_address
      current_user.accounts.each do |account|
        next if not account.currency_obj.coin?

        if account.payment_addresses.blank?
          account.payment_addresses.create(currency: account.currency)
        else
          address = account.payment_addresses.last
          address.gen_address if address.address.blank?
        end
      end
      render nothing: true
    end

    def ideal_payment
      begin
        account = current_user.get_account('eur')
        fund_sources = current_user.fund_sources.with_currency('eur')
        deposit_params = {}
        deposit_params[:currency] = "eur"
        deposit_params[:member_id] = current_user.id
        deposit_params[:account_id] = account.id
        deposit_params[:amount] = params[:amount]
        deposit = Deposit.new(deposit_params)
        deposit.save

        protocol = request.protocol || "http"
        host_port = request.host_with_port;

        mollie = Mollie::API::Client.new
        mollie.setApiKey mollie_api_key

        payment = mollie.payments.create \
          :amount       => params[:amount].to_f + mollie_transaction_fee,
          :description  => "Euro deposit " + deposit.id.to_s,
          :redirectUrl  => "#{protocol}#{host_port}/funds/mollie_payment_result?deposit_id=#{deposit.id}",
          :metadata     => {
            :deposit_id => deposit.id
          },
          :method       => Mollie::API::Object::Method::IDEAL,
          :issuer       => params[:issuer].empty? ? params[':issuer'] : nil

        account = current_user.get_account('eur')
        fund_sources = current_user.fund_sources.with_currency('eur')
        deposit.fiat_payment_transaction_id = payment.id

        if deposit.save
          redirect_to payment.getPaymentUrl
        else
          redirect_to "/funds/?error=" + URI::encode("Something went wrong with your deposit. Please try again.") + "#/deposits/eur"
        end
     rescue Mollie::API::Exception => ex
        redirect_to "/funds/?error=" + URI::encode(ex.message) + "#/deposits/eur"
     end
    end

    def mollie_payment_result
      mollie = Mollie::API::Client.new
      mollie.setApiKey mollie_api_key

      deposit = Deposit.find(params[:deposit_id])

      payment = mollie.payments.get deposit.fiat_payment_transaction_id

      ActiveRecord::Base.transaction do
        if payment.paid?
          begin
            deposit.submit!
          rescue
          end
          deposit.accept!
          unless FundSource.find_by(:uid => payment.details.consumerAccount, :extra => payment.details.consumerBic)
            new_fund_source = current_user.fund_sources.new fund_source_params(payment)
            new_fund_source.save
          end
          redirect_to '/funds#/deposits/eur'
        elsif payment.open? == false
          deposit.cancel!
          redirect_to '/funds?error=' + URI::encode('Deposit cancelled. Please try again.')  + '#/deposits/eur'
        else
          deposit.submit!
          redirect_to '/funds?error=' + URI::encode('Deposit could not be verified and may be cancelled or processed later.')  + '#/deposits/eur'
        end
      end
      
    end

    private

    def fund_source_params payment
      {"uid" => payment.details.consumerAccount,
       "extra" => payment.details.consumerBic,
       "currency" => "eur",
       "account_name" => payment.details.consumerName}
    end

    def setup_mollie
      @mollie_issuers = []
      mollie = Mollie::API::Client.new
      mollie.setApiKey mollie_api_key
      issuers = mollie.issuers.all
      issuers.each { |issuer|
        if issuer.method == Mollie::API::Object::Method::IDEAL
          @mollie_issuers.push(issuer)
        end
      }
    end

    def mollie_api_key
      "test_Z3JJFR6v898ByHBUwYmfNkMVybbuxC"
      #ENV['MOLLIE_KEY']
    end

    def mollie_transaction_fee
      0.45
      #ENV['MOLLIE_IDEAL_FEE']
    end

  end
end

