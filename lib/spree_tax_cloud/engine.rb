module SpreeTaxCloud
  class Engine < Rails::Engine
    require 'spree/core'
    isolate_namespace Spree
    engine_name 'spree_tax_cloud'

    config.autoload_paths += %W(#{config.root}/lib)

    # use rspec for tests
    config.generators do |g|
      g.test_framework :rspec
    end

    initializer "spree.shipstation.preferences", before: :load_config_initializers do |app|
      Spree::AppConfiguration.class_eval do
        preference :taxcloud_api_login_id, :string
        preference :taxcloud_api_key, :string
        preference :taxcloud_product_tic, :string, default: '00000'
        preference :taxcloud_shipping_tic, :string, default: '11010'
        preference :taxcloud_usps_user_id, :string
        preference :taxcloud_origin, :string, default: {}.to_json
        preference :taxclould_eligible_state_ids, :array, default: []
      end
    end

    def self.activate
      Dir.glob(File.join(File.dirname(__FILE__), '../../app/**/*_decorator*.rb')) do |c|
        Rails.configuration.cache_classes ? require(c) : load(c)
      end
    end
    config.to_prepare &method(:activate).to_proc
  end
end
