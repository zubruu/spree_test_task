class ImportsController < ApplicationController
  def new
    @import = Import.new
  end

  def create
    begin
      import = Import.create!(import_params)
      import.start_import
      render js: "alert('Import started in delayed_job')"
    rescue StandardError => e
      render js: "alert('Error: #{e.message}')"
    end
  end

  private

  def import_params
    params.require(:import).permit(:file)
  end
end
