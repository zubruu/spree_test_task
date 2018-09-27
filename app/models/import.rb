# frozen_string_literal: true

require 'csv'
# General worker class for imports
class Import < ActiveRecord::Base
  BATCH_SIZE = 2 # import size in single delayed_job

  has_attached_file :file, :content_type => [ "text/plain" ]
  validates_attachment_file_name :file, :matches => [/csv\Z/]

  def start_import
    Import.set_default
    import_model = ImportProduct # logic for switching imports
    Import.do_import(file.path, import_model, 0)
  end

  def self.do_import(file_path, import_model, drop_count = 0)
    end_of_file = false
    CSV.foreach(file_path, { headers: true, col_sep: ';' }).drop(drop_count).take(BATCH_SIZE).each do |row|
      end_of_file = true
      next if row.to_h.compact.blank?
      begin
        import_row = import_model.new(row.to_h.compact)
        import_row.do_import
      rescue StandardError => e
        log_error(e, row)
      end
    end
    return unless end_of_file
    Import.do_import(file_path, import_model, drop_count + BATCH_SIZE)
  end

  private

  class << self

    def set_default
      Spree::StockLocation.create!(name: 'default') if Spree::StockLocation.all.blank?
    end

    def log_error(error, row)
      Rails.logger.error("Error importing: row: #{row}, error: #{error}")
    end
  end
end
