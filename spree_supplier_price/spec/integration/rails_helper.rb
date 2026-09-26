# frozen_string_literal: true

# Run from the configured host application; never migrate a development DB.
ENV['RAILS_ENV'] = 'test'
require File.join(ENV.fetch('SPREE_HOST_ROOT', File.expand_path('../../../server', __dir__)), 'spec/rails_helper')
abort 'Install spree_supplier_price in the host Gemfile first' unless defined?(SpreeSupplierPrice::Engine)
