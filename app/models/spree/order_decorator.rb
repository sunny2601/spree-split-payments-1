Spree::Order.class_eval do
  before_validation :invalidate_old_payments, :if => :payment?
  validate :ensure_only_one_non_partial_payment_method_present_if_multiple_payments, :if => :payment?

  def available_partial_payments
    @available_partial_payments ||= Spree::PaymentMethod.active(user ? false : true).select(&:for_partial?)
  end

  def active_partial_payments?
    payments.valid.select(&:is_partial).count > 0
  end

  def active_partial_payments
    payments.valid.select(&:is_partial)
  end

  def display_total
      order_total = total
      active_partial_payments.each do |payment|
        order_total -= payment.amount
      end

      Spree::Money.new(order_total, { currency: currency })
  end

  private

  def checkout_payments
    payments.select { |payment| payment.checkout? }
  end

  def invalidate_old_payments
    checkout_payments.each do |payment|
      if !payment.not_to_be_invalidated
        payment.invalidate!
      end
    end
  end

  def ensure_only_one_non_partial_payment_method_present_if_multiple_payments
    if checkout_payments.many?
      payment_method_ids = checkout_payments.map(&:payment_method_id)
      non_partial_payment_method_ids =  payment_method_ids - available_partial_payments.map(&:id)
      if non_partial_payment_method_ids.size > 1
        errors[:base] << "Only one non partial payment method can be clubbed with partial payments."
        return false
      end
    end
  end

  def update_params_payment_source
    if has_checkout_step?("payment") && self.payment?
      insert_source_params

      if @updating_params[:order][:payments_attributes].first
        @updating_params[:order][:payments_attributes].first[:amount] = order_total_after_partial_payments
      end
    end
  end

  def insert_source_params
    @updating_params[:order][:payments_attributes] = []

    if @updating_params[:payment_source].present? 
      @updating_params[:payment_source].each do |payment_method_id,payment_source_attributes|     
        payments_attributes = {
          payment_method_id: payment_method_id,
          not_to_be_invalidated: true,
          source_attributes: payment_source_attributes
        }

        if Spree::PaymentMethod.find(payment_method_id).for_partial?
          #currently assuming that the only partial payment will be a valutec card
          card = Stumptown::Valutec::Card.new(
            card_number: payment_source_attributes[:number]
            )
          available_funds = card.balance.result
          if available_funds >= outstanding_balance
            payments_attributes[:amount] = outstanding_balance
          else
            payments_attributes[:amount] = available_funds
          end
        end 
        @updating_params[:order][:payments_attributes] <<  payments_attributes
      end
      @updating_params.delete(:payment_source)
    end
  end

  def order_total_after_partial_payments
    amount = 0
    @updating_params[:order][:payments_attributes].each do |payments_attributes|
      amount += payments_attributes[:amount].to_f
    end
    outstanding_balance - amount
  end
end
