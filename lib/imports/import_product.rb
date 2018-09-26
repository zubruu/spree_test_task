class ImportProduct

  TAXONS_AVAIABLE_PARAMS = %w(category category_id)
  STOCK_AVAIABLE_PARAMS = %w(stock_total)
  EXCEPT_PARAMS = TAXONS_AVAIABLE_PARAMS + STOCK_AVAIABLE_PARAMS

  PRODUCT_REPLACE_PARAMS_NAME = {'availability_date' => 'available_on'}
  VARIANTS_OPTIONS_PREFIX = 'option_'


  def initialize(params)
    @params = params
    @procceded_params = {}
    @procceded_stock_params = nil
    @last_procceded_product = nil
    @variant_options = []
  end

  def do_import
    procced_params
    master_product = Spree::Product.find_by(slug: @params['slug']) if @params['slug'].present?
    master_product.present? ? procced_existing_product(master_product) : procced_new_product
  end

  private

  def procced_existing_product(product)
    @last_procceded_product = product
    @last_procceded_product.update!(@procceded_params)
    @last_procceded_variant = find_variant if @procceded_params['option_values_hash'] #@last_procceded_product.variants_including_master.last
    @last_procceded_variant ||= @last_procceded_product.master
    update_stock_items
  end

  def procced_new_product
    @last_procceded_variant = Spree::Product.create!(@procceded_params).variants_including_master.last
    update_stock_items
  end

  def procced_params
    @procceded_params = @params.except(*EXCEPT_PARAMS).dup
    replace_product_params
    procced_variants_options
    procced_categories
    procced_shipping_categories
    procced_stock_params
  end

  def find_variant
    option_id = @procceded_params['option_values_hash'].values
    variant = Spree::OptionValueVariant.where(variant_id: @last_procceded_product.variants.pluck(:id), option_value_id: option_id).first
    variant ||= Spree::Variant.create!(product_id: @last_procceded_product.id, option_values: @variant_options)
    variant
  end

  def replace_product_params
    PRODUCT_REPLACE_PARAMS_NAME.each do |replaced_param, replace_param|
      @procceded_params[replace_param] = @procceded_params[replaced_param]
      @procceded_params.except!(replaced_param)
    end
  end

  def procced_variants_options
    option_values_hash = {}
    @procceded_params.keys.each do |key|
      next unless key.include?(VARIANTS_OPTIONS_PREFIX)
      next unless @procceded_params[key].present?
      type_name = key.split(VARIANTS_OPTIONS_PREFIX)[1]
      value = @procceded_params[key]
      @procceded_params.except!(key)

      type = Spree::OptionType.where('name = ? or presentation = ?', type_name, type_name).first
      type = Spree::OptionType.create!(name: type_name, presentation: type_name) unless type
      option_value = Spree::OptionValue.where('(name = ? or presentation = ?) and option_type_id = ?',
                                              value, value, type.id).first
      option_value = Spree::OptionValue.create!(name: value, presentation: value, option_type_id: type.id) unless option_value
      option_values_hash[type.id] = [option_value.id]
      @variant_options << option_value
    end
    @procceded_params['option_values_hash'] = option_values_hash if option_values_hash.present?
  end

  def procced_categories
    if @params['category']
      category = Spree::Taxon.find_by(name: @params['category'])
    elsif @params['category_id']
      category = Spree::Taxon.find_by(id: @params['category_id'])
    else
      return # no category
    end

    if category
      @procceded_params['taxon_ids'] = [category.id]
    else
      @procceded_params['taxons'] = [Spree::Taxon.new(name: @params['category'])] # New category
    end
  end

  def procced_shipping_categories
    category = if @params['shipping_category']
                 Spree::ShippingCategory.find_by(name: @params['category'])
               elsif @params['shipping_category_id']
                 Spree::ShippingCategory.find_by(id: @params['shipping_category_id'])
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
    @procceded_stock_params = @params['stock_total']
  end

  def update_stock_items
    if @procceded_stock_params # for default stock location
      stock_location = Spree::StockLocation.first # default
      update_stock_item(@last_procceded_variant, stock_location, @procceded_stock_params)
    end
    # TODO: Diffrent stock locations
  end

  def update_stock_item(variant, location, stock_total)
    stock_item = Spree::StockItem.find_by(variant_id: variant.id, stock_location_id: location.id)
    if stock_item
      stock_item.set_count_on_hand(stock_total)
    else
      Spree::StockItem.create(variant_id: variant.id, stock_location_id: location.id, count_on_hand: stock_total)
    end
  end
end