# frozen_string_literal: true

module SpreeSupplierPrice
  module Orders
    class Complete < Spree::Orders::Complete
      workflow_key 'orders.complete'

      private

      def ensure_not_canceled
        super
        Capture.call(order: order)
      rescue SpreeSupplierPrice::Error => error
        failure(order, code: 'supplier_price_invalid', message: error.message)
      end

      def place_order
        super
        return unless order.line_items.any?(&:supplier_price_settlement_snapshot?)

        # Inside core's placement transaction, after splitting and before
        # automatic fulfillment. A ledger must never see an uncommissioned
        # supplier order. The normal order.placed subscriber then replays
        # the SAME idempotent service without writing duplicate lines.
        result = Spree.commissions_commission_order_service.call(order: order)
        failure(order, result.error) if result.failure?
      rescue SpreeSupplierPrice::Error => error
        failure(order, code: 'supplier_price_invalid', message: error.message)
      end
    end
  end
end
