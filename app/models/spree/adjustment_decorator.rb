Spree::Adjustment.class_eval do
  scope :tax_cloud, -> { where(source_type: 'Spree::TaxCloudTransaction') }
end