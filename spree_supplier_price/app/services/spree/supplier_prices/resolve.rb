# frozen_string_literal: true
module Spree
  module SupplierPrices
    class Resolve
      def self.call(seller:, variant:, currency:)
        Spree::SupplierPrice.active_for(seller: seller, variant: variant, currency: currency)&.amount
      end
    end
  end
end
