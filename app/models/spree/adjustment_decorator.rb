Spree::Adjustment.class_eval do
  scope :tax_cloud, -> { where(originator_type: 'Spree::TaxCloudTransaction') }
end