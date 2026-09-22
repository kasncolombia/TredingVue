class CreateBrokers < ActiveRecord::Migration[8.0]
  def change
    create_table :brokers do |t|
      t.string  :name,                  null: false
      t.string  :logo_filename
      t.string  :category,              default: "broker"
      t.boolean :supports_autosync,    default: false
      t.boolean :supports_file_upload, default: true
      t.boolean :supports_manual,      default: true
      t.text    :autosync_instructions
      t.text    :csv_instructions

      t.timestamps
    end
  end
end
