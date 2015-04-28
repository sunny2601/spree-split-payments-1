Spree Split Payments 
=========================

This extension provides the feature for a spree store to allow user to club payment methods to pay for the order.

Easily configurable from the admin end where one can select which payment methods should be allowed for clubbing and their priorities which can be used while creating payments and displaying them to the user.

It has been customized extensively by Instrument to be compatible with Spree 2.4.4

Installation
------------

Add spree-split-payments to your `Gemfile`:

```ruby
gem 'spree-split-payments'
```

Bundle your dependencies and run the installation generator:

```shell
bundle
bundle exec rails g spree_split_payments:install
```

Integration
-----------
This is not in use as this is implemented for Instrument.

The extension needs a way to find out the maximum amount that can be made via a payment method. To do so it sends a message to the user object as:

```ruby
#{payment_method.class.name.demodulize.underscore}_for_partial_payments

# for example : for Spree::PaymentMethod::LoyaltyPoints it calls for
# loyalty_points_for_partial_payments
# on current_user
```

So you can either

1) Alias an exising method like
```ruby
# models/spree/user_decorator.rb
alias_method :loyalty_points_for_partial_payments, :loyalty_points_equivalent_currency

# where loyalty_points_equivalent_currency is the method provided by
# Spree::PaymentMethod::LoyaltyPoints extension.
```

2) Define a method under user class. For example for Spree::PaymentMethod::LoyaltyPoints)
```ruby
#models/spree/user_decorator.rb
Spree::User.class_eval do
  ...

  def loyalty_points_for_partial_payments
    # logic goes here
  end

  ...

end
```

Testing
-------

Be sure to bundle your dependencies and then create a dummy test app for the specs to run against.

```shell
bundle
bundle exec rake test_app
bundle exec rspec spec
```

When testing your applications integration with this extension you may use it's factories.
Simply add this require statement to your `spec_helper`:

```ruby
require 'spree-split-payments/factories'
```

Contributing
------------

1. Fork the repo.
2. Clone your repo.
3. Run `bundle install`.
4. Run `bundle exec rake test_app` to create the test application in `spec/test_app`.
5. Make your changes.
6. Ensure specs pass by running `bundle exec rspec spec`.
7. Submit your pull request.

Instrument Implementation
-------------------------

This gem has been customized for Instrument and relies on the Stumptown::Valutec library and the Valutec model in the Spree application this was written to be used for.

This gem was tailored to a loyalty type program to split payments. We have customised it to use external payment programs, specifically the Valutec Gift Card program we have integrated. On checkout, the updating parameters are sorted and filtered by this gem when the update_params_payment_souce is called in Spree::Checkout.update. The params are sorted and blank ones are discarded. Partial payments are added to the order first and if to total of the partial payment are enough to cover the order total, then all other payment methods are discarded. Care is taken to preven downstream problems from this action.

If the payment is required after the partial payments are saved, then other forms of payment are saved.

A user can submit mulitple gift cards for multiple partial payments. They may not apply the same gift card number to the same order more than once. 

Once a gift card is added as payment to an order it may not be removed however each time credit card information is entered, any existing non partial payments will be invalidated. For example if a user enters a credit card and a payment record is created in the spree database, if the user leaves the payment flow, and returne, that payment record will be invalidated and any future credit card payments will supercede. That is not the case with Gift Card partial payments; they will remain.

In general there are some significant logic gymnastics conducted to support the front end flow for submitting the entire payment form for a gift card AND then later for any credit card payments. 


Credits
-------

[![vinsol.com: Ruby on Rails, iOS and Android developers](http://vinsol.com/vin_logo.png "Ruby on Rails, iOS and Android developers")](http://vinsol.com)

Copyright (c) 2014 [vinsol.com](http://vinsol.com "Ruby on Rails, iOS and Android developers"), released under the New MIT License
