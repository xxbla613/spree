# frozen_string_literal: true

module SpreeSupplierPrice
  module Commissions
    class CalculateLine < Spree::Commissions::CalculateLine
      private

      def charge_for(rate, subject, currency)
        if subject.is_a?(Spree::LineItem) &&
           subject.supplier_price_settlement_snapshot?

          SpreeSupplierPrice::Margin.call(
            line_item: subject,
            currency: currency
          )
        else
          super
        end
      end
    end
  end
end