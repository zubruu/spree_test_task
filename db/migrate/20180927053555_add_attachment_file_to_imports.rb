class AddAttachmentFileToImports < ActiveRecord::Migration[5.1]
  def self.up
    add_attachment :imports, :file
  end

  def self.down
    remove_attachment :imports, :file
  end
end
