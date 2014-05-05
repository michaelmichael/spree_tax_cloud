# Designed to be the Originator for an Adjustment on an order.

require_dependency 'spree/order'

module Spree
  class TaxCloudTransaction < ActiveRecord::Base
    belongs_to :order

    validates :order, presence: true

    has_one :adjustment, as: :source

    has_many :cart_items, class_name: 'TaxCloudCartItem', dependent: :destroy

    # called when order updates adjustments
    def compute_amount(target)
      return if (adjustment.blank? || order.item_total == 0)

      rate = amount / order.item_total
      tax  = (order.item_total - order.promotions_total) * rate
      tax  = 0 if tax.nan?

      tax
    end

    def lookup
      create_cart_items
      response = tax_cloud.lookup(self)
      if response.success?
        transaction do
          result = response.body[:lookup_response][:lookup_result]
          if result[:cart_items_response].blank?
            raise ::SpreeTaxCloud::Error, result[:messages][:response_message][:message]
          end
          response_cart_items = Array.wrap result[:cart_items_response][:cart_item_response]
          response_cart_items.each do |response_cart_item|
            cart_item = cart_items.find_by_index(response_cart_item[:cart_item_index].to_i)
            cart_item.update_attribute(:amount, response_cart_item[:tax_amount].to_f)
          end
        end
      else
        raise ::SpreeTaxCloud::Error, 'TaxCloud response unsuccessful!'
      end
    end

    def capture
      tax_cloud.capture(self)
    end

    def amount
      cart_items.sum(:amount)
    end

    private

    def cart_price
      cart_items.inject(0) do |sum, item|
        sum + (item.price * item.quantity)
      end
    end

    def tax_cloud
      @tax_cloud ||= Spree::TaxCloud.new
    end

    def create_cart_items
      cart_items.clear
      index = 0
      order.line_items.each do |line_item|
        cart_items.create!({
          index:     (index += 1),
          tic:       Spree::Config.taxcloud_product_tic,
          sku:       line_item.variant.sku.presence || line_item.variant.id,
          quantity:  line_item.quantity,
          price:     line_item.price.to_f,
          line_item: line_item
        })
      end

      cart_items.create!({
        index:    (index += 1),
        tic:      Spree::Config.taxcloud_shipping_tic,
        sku:      'SHIPPING',
        quantity: 1,
        price:    order.ship_total.to_f
      })
    end
  end
end
