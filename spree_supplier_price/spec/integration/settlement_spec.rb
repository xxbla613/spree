# frozen_string_literal: true
require_relative 'rails_helper'

RSpec.describe 'Supplier settlement integration', type: :model do
  let(:store) { Spree::Store.default || create(:store) }
  let(:seller) { create(:seller, :approved, store: store, settlement_mode: :supplier_price) }
  let(:order) { create(:order, store: store, currency: 'USD') }
  let(:product) { create(:product, store: store, seller: seller) }
  let!(:item) { create(:line_item, order: order, variant: product.default_variant, price: 100, quantity: 2) }

  def approve(amount: 60, currency: 'USD', variant: item.variant, seller: self.seller)
    Spree::SupplierPrice.create!(seller: seller, variant: variant, amount: amount, currency: currency,
                                 state: :approved, approved_at: Time.current)
  end

  def capture
    SpreeSupplierPrice::Capture.call(order: order)
  end

  def commission
    Spree.commissions_commission_order_service.call(order: order)
  end

  it 'registers all three beta4 dependency seams' do
    expect(Spree.carts_complete_workflow).to eq(SpreeSupplierPrice::Carts::Complete)
    expect(Spree.order_complete_workflow).to eq(SpreeSupplierPrice::Orders::Complete)
    expect(Spree.commissions_commission_order_service).to eq(SpreeSupplierPrice::Commissions::CommissionOrder)
  end

  it 'creates margin commission with no configured commission rate' do
    approve
    capture
    result = commission
    expect(result).to be_success
    expect(result.value.one?).to be true
    expect(result.value.first).to have_attributes(amount: 80, line_item_id: item.id, commission_rate_id: nil)
    expect(order.reload.commission_amount_total).to eq(80)
  end

  it 'keeps the order customer total unchanged' do
    approve
    capture
    expect { commission }.not_to change { order.reload.total }
  end

  it 'uses the frozen cost after approval and seller mode change' do
    original = approve
    capture
    approve(amount: 70)
    seller.update!(settlement_mode: :commission)
    capture
    expect(item.reload).to have_attributes(supplier_price: 60, supplier_price_record_id: original.id)
    expect(commission.value.first.amount).to eq(80)
  end

  it 'does not duplicate commission when replayed' do
    approve
    capture
    commission
    expect { commission }.not_to change(Spree::CommissionLine, :count)
  end

  it 'rejects missing approved prices and rolls back all snapshots' do
    expect { capture }.to raise_error(SpreeSupplierPrice::Error, /No approved/)
    expect(item.reload.supplier_settlement_mode).to be_nil
  end

  it 'does not substitute another currency' do
    approve(currency: 'EUR')
    expect { capture }.to raise_error(SpreeSupplierPrice::Error, /No approved/)
  end

  it 'does not accept draft prices' do
    Spree::SupplierPrice.create!(seller: seller, variant: item.variant, amount: 60, currency: 'USD')
    expect { capture }.to raise_error(SpreeSupplierPrice::Error, /No approved/)
  end

  it 'refuses negative margin and rolls the snapshot back' do
    approve(amount: 110)
    expect { capture }.to raise_error(SpreeSupplierPrice::Error, /exceeds/)
    expect(item.reload.supplier_price).to be_nil
  end

  it 'records zero margin as a real settlement record' do
    approve(amount: 100)
    capture
    expect(commission.value.first.amount).to eq(0)
  end

  it 'prevents changing a captured snapshot via model writes' do
    approve
    capture
    expect(item.reload.update(supplier_price: 50)).to be false
    expect(item.reload.supplier_price).to eq(60)
  end

  it 'does not reinterpret a legacy order using current seller mode' do
    create(:commission_rate, store: store, kind: 'percentage', value: 10)
    expect(commission.value.first.amount).to eq(20)
    expect(item.reload.supplier_price).to be_nil
  end

  it 'preserves ordinary percentage commission in a mixed order' do
    ordinary = create(:seller, :approved, store: store)
    other_product = create(:product, store: store, seller: ordinary)
    other = create(:line_item, order: order, variant: other_product.default_variant, price: 50, quantity: 1)
    create(:commission_rate, store: store, kind: 'percentage', value: 10)
    approve
    capture
    lines = commission.value.index_by(&:line_item_id)
    expect(lines[item.id].amount).to eq(80)
    expect(lines[other.id].amount).to eq(5)
  end

  it 'uses the native commission tax resolver' do
    approve
    capture
    allow_any_instance_of(Spree::TaxProvider::Internal).to receive(:service_tax_rate).and_return(BigDecimal('0.2'))
    expect(commission.value.first).to have_attributes(amount: 80, tax_amount: 16, total: 96)
  end

  it 'rejects an approval for a variant owned by another seller' do
    other = create(:seller, :approved, store: store)
    price = Spree::SupplierPrice.new(seller: other, variant: item.variant, amount: 60, currency: 'USD')
    expect(price).not_to be_valid
    expect(price.errors[:variant]).not_to be_empty
  end

  it 'rolls back earlier lines when a later line has no approved price' do
    approve
    second = create(:product, store: store, seller: seller)
    create(:line_item, order: order, variant: second.default_variant, price: 100, quantity: 1)
    expect { capture }.to raise_error(SpreeSupplierPrice::Error)
    expect(order.line_items.reload.pluck(:supplier_settlement_mode)).to all(be_nil)
  end

  it 'blocks draft completion before attempting payment on a missing price' do
    expect(order).not_to receive(:process_payments!)
    result = Spree.order_complete_workflow.call(order: order)
    expect(result).to be_failure
    expect(order.reload.completed_at).to be_nil
  end

  it 'places supplier orders through completion and replays safely' do
    approve
    result = Spree.order_complete_workflow.call(order: order, payment_pending: true)
    expect(result).to be_success
    expect(order.reload.completed_at).to be_present
    expect(item.reload.supplier_price).to eq(60)
    expect(order.commission_lines.sum(:amount)).to eq(80)
    expect { Spree.order_complete_workflow.call(order: order, payment_pending: true) }
      .not_to change(Spree::CommissionLine, :count)
  end

  it 'retains supplier snapshots across native seller splitting' do
    approve
    other = create(:seller, :approved, store: store, settlement_mode: :supplier_price)
    other_product = create(:product, store: store, seller: other)
    other_item = create(:line_item, order: order, variant: other_product.default_variant, price: 50, quantity: 1)
    approve(amount: 30, variant: other_item.variant, seller: other)
    result = Spree.order_complete_workflow.call(order: order, payment_pending: true)
    expect(result).to be_success
    expect(item.reload.supplier_price).to eq(60)
    expect(other_item.reload.supplier_price).to eq(30)
    expect(item.order_id).not_to eq(other_item.order_id)
    expect(Spree::CommissionLine.where(line_item_id: [item.id, other_item.id]).sum(:amount)).to eq(100)
  end
end
