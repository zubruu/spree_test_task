require 'csv'

class Import

  TAXONS_AVAIABLE_PARAMS = %w(category category_id)
  STOCK_AVAIABLE_PARAMS = %w(stock_total)
  EXCEPT_PARAMS = TAXONS_AVAIABLE_PARAMS + STOCK_AVAIABLE_PARAMS

  PRODUCT_REPLACE_PARAMS_NAME = {'availability_date' => 'available_on'}
  VARIANTS_OPTIONS_PREFIX = 'option_'


  def initialize(file_path, import_type)
    @file_path = file_path
    @import_model = import_type
  end

  def import
    set_default
    CSV.foreach('sample.csv', {headers: true, col_sep: ';'}) do |row|
      next unless row.to_h.compact.present?
      import_row = @import_model.new(row.to_h.compact)
      import_row.do_import
    end
  end

  private

  def set_default
    Spree::StockLocation.create!(name: 'default') if Spree::StockLocation.all.blank?
  end

  def self.clean
    Spree::Product.all.delete_all
    Spree::StockLocation.all.delete_all
    Spree::StockItem.all.delete_all
    Spree::ShippingCategory.all.delete_all
    Spree::Taxon.all.delete_all
    Spree::Variant.all.delete_all
    Spree::OptionValue.all.delete_all
    Spree::OptionType.all.delete_all
  end

end