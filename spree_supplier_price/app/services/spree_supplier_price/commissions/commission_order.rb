# frozen_string_literal: true

module SpreeSupplierPrice
  module Commissions
    class CommissionOrder < Spree::Commissions::CommissionOrder
      private

      # Keep core's transaction, replay guard, unique indexes and rollups.
      # Never consult today's seller mode to reinterpret a placed order.
      def commission_seller(order:, seller:, line_items:, rates:, categories:, deliveries:)
        supplier, ordinary = line_items.partition(&:supplier_price_settlement_snapshot?)
        lines = ordinary.empty? ? [] : super(order: order, seller: seller, line_items: ordinary,
                                             rates: rates, categories: categories, deliveries: deliveries)
        return lines if supplier.empty?

        # An unsaved config object supplies only the native tax resolver's
        # optional override. It is never attached to a CommissionLine.
        tax_config = Spree::CommissionRate.new(kind: 'fixed', value: 0)
        tax_result = Spree.commissions_resolve_tax_rate_service.call(rate: tax_config, seller: seller, order: order)
        raise Error, tax_result.error.to_s if tax_result.failure?

        tax = tax_result.value
        supplier.each do |item|
          amount = Margin.call(line_item: item, currency: order.currency)
          precision = Spree::Money::Rounding.precision(order.currency)
          tax_amount = Spree::Money::Rounding.quantize(amount * tax.rate, precision)
          lines << Spree::CommissionLine.create!(
            order: order, seller: seller, line_item: item, commission_rate: nil,
            kind: 'fixed', rate: 0, amount: amount, tax_amount: tax_amount,
            total: amount + tax_amount, currency: order.currency,
            metadata: { 'settlement_mode' => 'supplier_price', 'supplier_price' => item.supplier_price.to_s,
                        'supplier_price_record_id' => item.supplier_price_record_id, 'basis' => 'discounted_net_merchandise' },
            **tax.to_line_attributes
          )
        end
        lines
      end
    end
  end
end
