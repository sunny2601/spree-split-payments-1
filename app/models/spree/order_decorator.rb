Spree::Order.class_eval do
  before_validation :invalidate_old_payments, :if => :payment?
  validate :ensure_only_one_non_partial_payment_method_present_if_multiple_payments, :if => :payment?

  def available_partial_payments
    @available_partial_payments ||= Spree::PaymentMethod.active(user ? false : true).select(&:for_partial?)
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
    #payments_attributes_hash = Hash[@updating_params[:order][:payments_attributes].map.with_index.to_a]
    @updating_params[:order][:payments_attributes] = [{}]

    if @updating_params[:payment_source].present? 
      @updating_params[:payment_source].each do |payment_method_id,payment_source_attributes|     
        payments_attributes = {:payment_method_id => payment_method_id, :not_to_be_invalidated => true, :source_attributes => payment_source_attributes} 

        if Spree::PaymentMethod.find(payment_method_id).for_partial?
          # funds = Spree::PaymentMethod.find_by(id:payment_method_id).available_funds
          # puts funds
          # payments_attributes[:amount] = funds  #this needs to go out and get the max amount
          payments_attributes[:amount] = 5
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
