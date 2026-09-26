# frozen_string_literal: true
require_relative '../../app/services/spree/supplier_prices/calculate'

RSpec.describe Spree::SupplierPrices::Calculate do
  let(:seller) { double(supplier_price_settlement?: true) }
  let(:line_item) { double(seller: seller, supplier_price: BigDecimal('12.3456'), quantity: 3) }

  it 'multiplies the snapshot without rounding away precision' do
    expect(described_class.call(line_item: line_item)).to eq(BigDecimal('37.0368'))
  end

  it 'rejects a missing snapshot instead of settling at zero' do
    allow(line_item).to receive(:supplier_price).and_return(nil)
    expect { described_class.call(line_item: line_item) }.to raise_error(described_class::MissingSnapshot)
  end

  it 'leaves commission-mode lines without snapshots alone' do
    allow(line_item).to receive(:supplier_price).and_return(nil)
    allow(seller).to receive(:supplier_price_settlement?).and_return(false)
    expect(described_class.call(line_item: line_item)).to be_nil
  end

  it 'leaves platform-owned lines without snapshots alone' do
    allow(line_item).to receive_messages(supplier_price: nil, seller: nil)
    expect(described_class.call(line_item: line_item)).to be_nil
  end

  it 'uses the captured price after the seller changes modes' do
    allow(seller).to receive(:supplier_price_settlement?).and_return(false)
    expect(described_class.call(line_item: line_item)).to eq(BigDecimal('37.0368'))
  end

  [0, -1].each do |amount|
    it 'rejects non-positive snapshots' do
      allow(line_item).to receive(:supplier_price).and_return(amount)
      expect { described_class.call(line_item: line_item) }.to raise_error(described_class::InvalidSnapshot)
    end
  end
end
