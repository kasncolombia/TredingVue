class Broker < ApplicationRecord
  has_many :trading_accounts, dependent: :nullify

  validates :name, presence: true, uniqueness: true

  CATEGORIES = %w[broker prop_firm crypto_exchange platform].freeze

  def logo_url
    if logo_filename.present?
      "compañias/#{logo_filename}"
    else
      nil
    end
  end
end
