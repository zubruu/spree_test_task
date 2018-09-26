require 'csv'

class ImportProducts

  TAXONS_AVAIABLE_PARAMS = %w(category category_id)
  STOCK_AVAIABLE_PARAMS = %w(stock_total)
  EXCEPT_PARAMS = TAXONS_AVAIABLE_PARAMS + STOCK_AVAIABLE_PARAMS

  PRODUCT_REPLACE_PARAMS_NAME = {'availability_date' => 'available_on'}


  def initialize(file_path)
    @file_path = file_path
    @procceded_params = nil
    @procceded_stock_params = nil
    @last_procceded_product = nil
    @row_params = nil
  end

  def import
    Spree::StockLocation.create!(name: 'default') # TODO
    CSV.foreach('sample.csv', {headers: true, col_sep: ';'}) do |row|
      @row_params = row.to_h.compact
      procced_row if @row_params.present?
    end
  end

  def validate_row_params

  end

  def procced_row
    master_product = Spree::Product.find_by(slug: @row_params['slug']) if @row_params['slug'].present?
    master_product.present? ? procced_existing_product(master_product) : procced_new_product
  end

  def procced_existing_product(product)
    procced_params
    @last_procceded_product = product
    @last_procceded_product.update(@procceded_params)
    update_stock_items
  end

  def procced_new_product
    procced_params
    @last_procceded_product = Spree::Product.create!(@procceded_params)
    update_stock_items
  end

  def procced_params
    @procceded_params = @row_params.except(*EXCEPT_PARAMS).dup
    replace_product_params
    procced_categories
    procced_shipping_categories
    procced_stock_params
  end

  def replace_product_params
    PRODUCT_REPLACE_PARAMS_NAME.each do |replaced_param, replace_param|
      @procceded_params[replace_param] = @procceded_params[replaced_param]
      @procceded_params.except!(replaced_param)
    end
  end

  def procced_categories
    if @row_params['category']
      category = Spree::Taxon.find_by(name: @row_params['category'])
    elsif @row_params['category_id']
      category = Spree::Taxon.find_by(id: @row_params['category_id'])
    else
      return # no category
    end

    if category
      @procceded_params['taxon_ids'] = [category.id]
    else
      @procceded_params['taxons'] = [Spree::Taxon.new(name: @row_params['category'])] # New category
    end
  end

  def procced_shipping_categories
    category = if @row_params['shipping_category']
                 Spree::ShippingCategory.find_by(name: @row_params['category'])
               elsif @row_params['shipping_category_id']
                 Spree::ShippingCategory.find_by(id: @row_params['shipping_category_id'])
               else
                 Spree::ShippingCategory.first # deafult one #error
               end

    if category
      @procceded_params['shipping_category_id'] = category.id
    else
      @procceded_params['shipping_category'] =  Spree::ShippingCategory.new(name: 'default')
    end
  end

  def procced_stock_params
    @procceded_stock_params = @row_params['stock_total']
  end

  def update_stock_items
    if @procceded_stock_params # for default stock location
      stock_location = Spree::StockLocation.first # default
      update_stock_item(@last_procceded_product, stock_location, @procceded_stock_params)
    end
    # TODO: Diffrent stock locations
  end

  def update_stock_item(variant, location, stock_total)
    byebug
    stock_item = Spree::StockItem.find_by(variant_id: variant.id, stock_location_id: location.id)
    if stock_item
      stock_item.set_count_on_hand(stock_total)
    else
      Spree::StockItem.create(variant_id: variant.id, stock_location_id: location.id, count_on_hand: stock_total)
    end
  end

  def self.clean
    Spree::Product.all.delete_all
    Spree::StockLocation.all.delete_all
    Spree::StockItem.all.delete_all
    Spree::ShippingCategory.all.delete_all
    Spree::Taxon.all.delete_all
    Spree::Variant.all.delete_all
  end

end