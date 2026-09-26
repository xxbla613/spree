# frozen_string_literal: true
module Spree
  class SupplierPrice < Spree.base_class
    belongs_to :seller, class_name: 'Spree::Seller', inverse_of: :supplier_prices
    belongs_to :variant, class_name: 'Spree::Variant'
    # Phase one is console/admin managed; no seller submission API exists.
    belongs_to :submitted_by, class_name: Spree.admin_user_class.to_s, optional: true
    belongs_to :approved_by, class_name: Spree.admin_user_class.to_s, optional: true
    enum :state, { draft: 0, approved: 1 }, default: :draft
    validates :amount, numericality: { greater_than: 0 }
    validates :currency, presence: true, length: { is: 3 }
    validates :currency, inclusion: { in: ->(_) { ::Money::Currency.all.map(&:iso_code) } }
    validates :approved_at, presence: true, if: :approved?
    validate :variant_belongs_to_seller
    scope :approved_for, ->(seller, variant, currency) {
      where(seller: seller, variant: variant, currency: currency, state: :approved)
    }
    def self.active_for(seller:, variant:, currency:)
      approved_for(seller, variant, currency).order(approved_at: :desc, id: :desc).first
    end
    private
    def variant_belongs_to_seller
    return unless seller && variant

    unless variant.resolved_seller_id == seller.id
      errors.add(:variant, 'must belong to the seller')
    end
end
  end
end
