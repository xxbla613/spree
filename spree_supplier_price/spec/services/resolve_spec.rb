# frozen_string_literal: true
require_relative '../../app/services/spree/supplier_prices/resolve'

RSpec.describe Spree::SupplierPrices::Resolve do
  let(:price_model) { Class.new }
  before { stub_const('Spree::SupplierPrice', price_model) }

  it 'looks up exactly the requested seller, variant, and currency' do
    expect(price_model).to receive(:active_for).with(seller: :seller, variant: :variant, currency: 'USD')
      .and_return(double(amount: '12.3456'))
    expect(described_class.call(seller: :seller, variant: :variant, currency: 'USD')).to eq('12.3456')
  end

  it 'returns nil when no approved price exists' do
    allow(price_model).to receive(:active_for).and_return(nil)
    expect(described_class.call(seller: :seller, variant: :variant, currency: 'EUR')).to be_nil
  end
end
