# frozen_string_literal: true
require 'test_helper'
class ImportTest < ActiveSupport::TestCase
  setup do
    Delayed::Worker.delay_jobs = false
  end

  test 'general_import' do
    import = Import.create(file: File.open("#{fixture_path}products.csv"))
    assert_difference 'Spree::Product.all.count', 3 do
      assert_difference 'Spree::Variant.all.count', 6 do
        import.start_import
      end
    end
    product = Spree::Product.find_by(slug: 'ruby-on-rails-bag')
    assert product, 'Product from import dosen\'t exists'
    assert_equal 2, product.variants.count, 'Wrong number of product variants'
    assert_equal 70, product.total_on_hand, 'Wrong total number'
  end

  test 'wrong_import' do
    import = Import.create(file: File.open("#{fixture_path}sample-wrong.csv"))
    assert_difference 'Spree::Product.all.count', 0 do
      assert_difference 'Spree::Variant.all.count', 0 do
        import.start_import
      end
    end
  end
end