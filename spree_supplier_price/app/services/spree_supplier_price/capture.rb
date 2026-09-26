# frozen_string_literal: true

module SpreeSupplierPrice
  # Runs in PREPARE before cart payments, and before admin draft payments.
  # SplitBySeller moves these rows, so the snapshot travels to child orders.
  class Capture
    def self.call(order:)
      order.with_lock do
        return if order.completed?

        order.line_items.order(:id).lock.each do |item|
          if item.supplier_settlement_mode.nil?
            seller = item.seller
            if seller && seller.supplier_price_settlement?
              price = Spree::SupplierPrice.active_for(seller: seller, variant: item.variant, currency: order.currency)
              raise Error, "No approved supplier price for line item #{item.id} (#{order.currency})" unless price

              item.update!(supplier_settlement_mode: 'supplier_price', supplier_price: price.amount,
                           supplier_price_currency: order.currency, supplier_price_record_id: price.id)
            else
              item.update!(supplier_settlement_mode: 'commission', supplier_price: nil)
            end
          end
          Margin.call(line_item: item, currency: order.currency) if item.supplier_price_settlement_snapshot?
        end
      end
    end
  end
end
