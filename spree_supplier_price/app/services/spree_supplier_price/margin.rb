# frozen_string_literal: true

module SpreeSupplierPrice
  class Margin
    def self.call(line_item:, currency:)
      unless line_item.supplier_price_settlement_snapshot? && line_item.supplier_price &&
             line_item.supplier_price_currency == currency
        raise Error, 'Missing or mismatched supplier settlement snapshot'
      end
      precision = Spree::Money::Rounding.precision(currency)
      raise Error, 'Supplier settlement supports currencies with at most two decimal places in beta4' if precision > 2
      raise Error, 'Supplier settlement requires a positive quantity' unless line_item.quantity.positive?

      cost = Spree::SupplierPrices::Calculate.call(line_item: line_item)
      base = Spree::Commissions::CalculateLine.base_for(nil, line_item)
      raise Error, 'Supplier cost exceeds discounted net merchandise revenue' if cost > base

      amount = Spree::Money::Rounding.quantize(base - cost, precision)
      raise Error, 'Supplier margin exceeds the beta4 commission column capacity' if amount >= 100_000_000

      amount
    end
  end
end
