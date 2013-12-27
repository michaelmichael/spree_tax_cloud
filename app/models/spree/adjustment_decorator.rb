Spree::Adjustment.class_eval do
  scope :tax, -> { where(originator_type: ['Spree::TaxRate', 'Spree::TaxCloudTransaction']) }
end