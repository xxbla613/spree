# frozen_string_literal: true
Gem::Specification.new do |spec|
  spec.name = 'spree_supplier_price'
  spec.version = '0.1.0'
  spec.authors = ['Spree Supplier Price contributors']
  spec.summary = 'Supplier price settlement foundations for Spree 6'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.2'
  spec.files = Dir.chdir(__dir__) { Dir['app/**/*', 'db/**/*', 'lib/**/*', 'README.md'] }
  spec.add_dependency 'spree_core', '= 6.0.0.beta4'
end
