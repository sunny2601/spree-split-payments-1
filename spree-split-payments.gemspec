# -*- encoding: utf-8 -*-
# stub: spree-split-payments 1.0.0 ruby lib

Gem::Specification.new do |s|
  s.name = "spree-split-payments"
  s.version = "1.0.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Manish Kangia"]
  s.date = "2015-03-26"
  s.email = "info@vinsol.com"
  s.files = [".gitignore", ".rspec", ".travis.yml", "Gemfile", "LICENSE", "README.md", "Rakefile", "app/assets/javascripts/spree/backend/spree-split-payments.js", "app/assets/javascripts/spree/frontend/spree-split-payments.js", "app/assets/stylesheets/spree/backend/spree-split-payments.css", "app/assets/stylesheets/spree/frontend/spree-split-payments.css", "app/models/spree/order_decorator.rb", "app/models/spree/payment_decorator.rb", "app/models/spree/payment_method_decorator.rb", "app/overrides/add_partial_payment_form_fields_admin.rb", "bin/rails", "config/locales/en.yml", "config/routes.rb", "db/migrate/20140318063048_add_partial_payment_fields_to_spree_payment_method.rb", "db/migrate/20140318063049_add_is_partial_to_spree_payment.rb", "lib/generators/spree_split_payments/install/install_generator.rb", "lib/spree-split-payments.rb", "lib/spree_split_payments/engine.rb", "lib/spree_split_payments/factories.rb", "spec/models/spree/order_decorator_spec.rb", "spec/models/spree/payment_decorator_spec.rb", "spec/models/spree/payment_method_decorator_spec.rb", "spec/spec_helper.rb", "spec/support/partial_payment_methods.rb", "spree-split-payments.gemspec"]
  s.homepage = "http://vinsol.com"
  s.licenses = ["MIT"]
  s.required_ruby_version = Gem::Requirement.new(">= 1.9.3")
  s.requirements = ["none"]
  s.rubygems_version = "2.2.2"
  s.summary = "Provides the feature for a Spree store to allow user to club payment methods to pay for the order"
end
