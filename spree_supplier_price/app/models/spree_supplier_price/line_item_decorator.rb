# frozen_string_literal: true
module SpreeSupplierPrice
  module LineItemDecorator
    extend ActiveSupport::Concern

    SNAPSHOT_FIELDS = %w[supplier_price supplier_settlement_mode supplier_price_currency supplier_price_record_id].freeze

    included do
      belongs_to :supplier_price_record, class_name: 'Spree::SupplierPrice', optional: true
      validate :supplier_snapshot_is_immutable, on: :update
    end

    def supplier_price_settlement_snapshot?
      supplier_settlement_mode == 'supplier_price'
    end

    def supplier_price_amount
      supplier_price
    end

    private

    def supplier_snapshot_is_immutable
      frozen_snapshot = attribute_in_database('supplier_settlement_mode').present?
      completed_order = order_id && Spree::Order.where(id: order_id).where.not(completed_at: nil).exists?
      if (frozen_snapshot || completed_order) && SNAPSHOT_FIELDS.any? { |field| will_save_change_to_attribute?(field) }
        errors.add(:supplier_price, 'settlement snapshot cannot be changed')
      end
      if frozen_snapshot && supplier_price_settlement_snapshot? &&
         %w[seller_id variant_id currency].any? { |field| will_save_change_to_attribute?(field) }
        errors.add(:supplier_price, 'snapshot seller, variant and currency cannot be changed')
      end
    end
  end
end
