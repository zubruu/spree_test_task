# frozen_string_literal: true

require 'csv'
# General worker class for imports
class Import
  BATCH_SIZE = 2 # import size in single delayed_job

  def initialize(file_path, import_type)
    @file_path = file_path
    @import_model = import_type
    @file_length = CSV.read(file_path).length
  end

  def start_import
    Import.set_default
    Import.import(@file_path, @import_model, 0, @file_length)
  end

  def self.import(file_path, import_model, drop_count = 0, file_length)
    i = 0
    CSV.foreach('sample.csv', { headers: true, col_sep: ';' }).drop(drop_count).each do |row|
      next unless row.to_h.compact.present?
      begin
        import_row = import_model.new(row.to_h.compact)
        import_row.do_import
      rescue StandardError => e
        log_error(e, row)
      end
      i += 1
      break if drop_count + BATCH_SIZE == i
    end
    Import.delay.import(file_path, import_model, drop_count + BATCH_SIZE, file_length) if drop_count + BATCH_SIZE < file_length
  end

  class << self

    def set_default
      Spree::StockLocation.create!(name: 'default') if Spree::StockLocation.all.blank?
    end

    def log_error(error, row)
      Rails.logger.error("Error importing: row: #{row}, error: #{error}")
    end
  end
end
