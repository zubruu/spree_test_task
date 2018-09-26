# frozen_string_literal: true
require 'test_helper'
class ImportTest < ActiveSupport::TestCase
  setup do
    Delayed::Worker.delay_jobs = false
  end

  test 'general_import' do
    import = Import.new("#{fixture_path}products.csv", ImportProduct)
    assert_difference 'Spree::Product.all.count', 3 do
      assert_difference 'Spree::Variant.all.count', 6 do
        import.start_import
      end
    end
    product = Spree::Product.find_by(slug: 'ruby-on-rails-bag')
    assert product, 'Product from import dosen\'t exists'
    assert product.variants.count == 2, 'Wrong number of product variants'
    assert product.total_on_hand == 70, 'Wrong total number'
  end
end