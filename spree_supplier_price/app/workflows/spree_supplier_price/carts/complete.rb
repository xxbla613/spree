# frozen_string_literal: true

module SpreeSupplierPrice
  module Carts
    class Complete < Spree::Carts::Complete
      workflow_key 'carts.complete'

      private

      # Core's before_finalize hook is AFTER payment. The draft-copy seam
      # is inside PREPARE and after discounts/taxes have been copied.
      def create_draft_order!(cart)
        Spree::Order.transaction do
          draft = super
          Capture.call(order: draft)
          draft
        end
      rescue SpreeSupplierPrice::Error => error
        failure(cart, code: 'supplier_price_invalid', message: error.message)
      end
    end
  end
end
