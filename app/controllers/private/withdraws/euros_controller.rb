module Private::Withdraws
  class EurosController < ::Private::Withdraws::BaseController
    include ::Withdraws::Withdrawable
  end
end
