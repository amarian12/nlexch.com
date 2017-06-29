module Admin
  module Withdraws
    class EurosController < ::Admin::Withdraws::BaseController
      load_and_authorize_resource :class => '::Withdraws::Euro'

      def index
        start_at = DateTime.now.ago(60 * 60 * 24)
        @one_euros = @euros.with_aasm_state(:accepted, :processing).order("id DESC")
        @all_euros = @euros.without_aasm_state(:accepted, :processing).where('created_at > ?', start_at).order("id DESC")
      end

      def show
      end

      def update
        if @euro.may_process?
          @euro.process!
        elsif @euro.may_succeed?
          @euro.succeed!
        end

        redirect_to :back, notice: t('.notice')
      end

      def destroy
        @euro.reject!
        redirect_to :back, notice: t('.notice')
      end
    end
  end
end
