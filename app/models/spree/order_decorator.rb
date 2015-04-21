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

  def active_partial_payment_total
    total = 0
    active_partial_payments.each do |payment|
      total += payment.amount
    end
    total
  end

  def display_total
    Spree::Money.new(total - active_partial_payment_total, { currency: currency })
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
      # if existing card, make sure it is the first payemnt in the index
      @existing_card_id = @updating_params[:order] ? @updating_params[:order][:existing_card] : nil
      @existing_card_payment_id = @updating_params[:order] ? @updating_params[:order][:payments_attributes].first[:payment_method_id] : nil
      insert_source_params
      # If existing card, rotate the array so the partial
      # payment won't be the fist position in the
      # array. This is important because of the next step
      if @existing_card_id.present?
        @updating_params[:order][:payments_attributes].rotate!
      end

      return unless @updating_params[:order].key?(:payments_attributes)

      #set order total after partial payments on the first remaining non-partial payment method
      @updating_params[:order][:payments_attributes].each_with_index do |payments_attrs, index|
        unless Spree::PaymentMethod.find(payments_attrs[:payment_method_id]).for_partial?
          @updating_params[:order][:payments_attributes][index][:amount] = order_total_after_partial_payments
          break
        end
      end
    end
  end

  def insert_source_params
    @updating_params[:order][:payments_attributes] = []
    return unless @updating_params[:payment_source].present?

    # force procesing of partial paymets first
    insert_source_params_for_partial_payments

    if order_total_after_partial_payments > 0.00
      insert_souce_params_for_other_payments
    end

    # if there are no payments in the submission
    # then remove the payments attributes
    if @updating_params[:order][:payments_attributes] == []
      @updating_params[:order].delete(:payments_attributes)
    end

    @updating_params.delete(:payment_source)
  end

  def insert_souce_params_for_other_payments
    @updating_params[:payment_source].each do |payment_method_id,payment_source_attributes|
      unless Spree::PaymentMethod.find(payment_method_id).for_partial?
        if (payment_source_attributes[:number].empty? && !@existing_card_id.nil?) && @existing_card_payment_id == payment_method_id || (!payment_source_attributes[:number].empty? && @existing_card_id.nil?)
          payments_attributes = {
            payment_method_id: payment_method_id,
            not_to_be_invalidated: true,
            source_attributes: payment_source_attributes
          }
          @updating_params[:order][:payments_attributes] <<  payments_attributes
        end
      end
    end
  end

  def insert_source_params_for_partial_payments
    @updating_params[:payment_source].each do |payment_method_id,payment_source_attributes| 
      if Spree::PaymentMethod.find(payment_method_id).for_partial?
        payments_attributes = {
          payment_method_id: payment_method_id,
          not_to_be_invalidated: true,
          source_attributes: payment_source_attributes
        }
        #dont set payments_attributes to the order if the gift card number is empty
        #currently assuming that the only partial payment will be a valutec card
        unless payment_source_attributes[:number].empty?
          card = Stumptown::Valutec::Card.new(
            card_number: payment_source_attributes[:number]
            )
          available_funds = card.balance.result
          if available_funds >= outstanding_balance
            payments_attributes[:amount] = outstanding_balance

            @updating_params[:order].delete(:existing_card) if @existing_card_id
          
          else
            payments_attributes[:amount] = available_funds
          end
          @updating_params[:order][:payments_attributes] <<  payments_attributes
        end
      end
    end
  end

  def order_total_after_partial_payments
    amount = 0
    @updating_params[:order][:payments_attributes].each do |payments_attributes|
      amount += payments_attributes[:amount].to_f
    end
    (outstanding_balance - amount).round(2)
  end
end
