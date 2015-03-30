Spree::PaymentMethod.class_eval do

  def self.active(guest_checkout=false)
    all.select do |p|
      p.active && 
      (p.environment == Rails.env || p.environment.blank?)
    end
  end

  def guest_checkout?
    true
  end
end
