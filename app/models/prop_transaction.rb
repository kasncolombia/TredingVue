class PropTransaction < ApplicationRecord
  belongs_to :user
  belongs_to :prop_firm_account, optional: true

  validates :company_name, :transaction_type, :amount, :transaction_date, presence: true
  validates :amount, numericality: { greater_than: 0 }

  enum :transaction_type, { expense: "expense", payout: "payout" }, prefix: true
  enum :category, { 
    evaluacion: "evaluacion", 
    activacion: "activacion", 
    mensualidad: "mensualidad", 
    reset: "reset", 
    payout: "payout",
    otro: "otro"
  }, prefix: true

  scope :expenses, -> { where(transaction_type: "expense") }
  scope :payouts,  -> { where(transaction_type: "payout") }
  scope :recent,   -> { order(transaction_date: :desc, created_at: :desc) }

  # Utilidades para el Dashboard ROI
  def self.total_payouts
    payouts.sum(:amount)
  end

  def self.total_expenses
    expenses.sum(:amount)
  end

  def self.net_profit
    total_payouts - total_expenses
  end

  def self.roi_percentage
    exp = total_expenses
    return 0.0 if exp.zero?
    (net_profit / exp * 100).round(2)
  end
end
