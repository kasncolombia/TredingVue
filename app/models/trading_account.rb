class TradingAccount < ApplicationRecord
  belongs_to :user
  belongs_to :broker, optional: true
  belongs_to :prop_firm_account, optional: true
  has_many   :trades, dependent: :nullify

  validates :name, presence: true
  validates :connection_method, presence: true, inclusion: { in: %w[autosync file_upload manual] }

  TIME_ZONES = [
    "UTC",
    "America/New_York (EST/EDT)",
    "America/Chicago (CST/CDT)",
    "America/Denver (MST/MDT)",
    "America/Los_Angeles (PST/PDT)",
    "America/Bogota (COT)",
    "Europe/London (GMT/BST)",
    "Europe/Madrid (CET/CEST)"
  ].freeze

  DATE_FORMATS = [
    "YYYY-MM-DD",
    "MM/DD/YYYY",
    "DD/MM/YYYY",
    "YYYY/MM/DD HH:mm:ss"
  ].freeze
end
