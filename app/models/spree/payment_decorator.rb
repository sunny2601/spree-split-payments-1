Spree::Payment.class_eval do
  attr_accessor :not_to_be_invalidated
  before_create :mark_partial_if_payment_method_is_partial

  def self.partial
    where(is_partial: true)
  end

  def display_amount
    negative_amount = amount * -1
    Spree::Money.new(negative_amount, { currency: currency })
  end

  private
    def invalidate_old_payments
    end

    def mark_partial_if_payment_method_is_partial
      if payment_method && payment_method.for_partial?
        self.is_partial = true
      end
    end
end