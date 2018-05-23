# frozen_string_literal: true

# == Schema Information
#
# Table name: line_items
#
#  id                 :bigint(8)        not null, primary key
#  product_sku_id     :bigint(8)
#  order_id           :bigint(8)
#  ttc_price_cents    :integer          default(0), not null
#  ttc_price_currency :string           default("EUR"), not null
#  tree_plantation_id :bigint(8)
#  quantity           :integer          default(0), not null
#  recipient_name     :string
#  recipient_message  :text
#  certificate_date   :date
#  certificate_number :string
#  delivery_email     :string
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#
# Foreign Keys
#
#  fk_rails_...  (order_id => orders.id)
#  fk_rails_...  (product_sku_id => product_skus.id)
#  fk_rails_...  (tree_plantation_id => tree_plantations.id)
#

class LineItem < ApplicationRecord
  belongs_to :product_sku, autosave: true
  belongs_to :order
  belongs_to :tree_plantation, optional: true, autosave: true
  has_one_attached :certificate

  monetize :ttc_price_cents

  validates :quantity, presence: true, numericality: { greater_than_or_equal_to: 1 }
  validates :recipient_message, length: { maximum: 300 }

  before_validation :decrement_stock_quantities, prepend: true
  before_save :update_price

  delegate :certificable?, :classic?, :personnalized?, :tree?, :product, :product_images,
           :product_name, :product_ttc_price_cents, :product_weight, :certificate_background,
           :producer_latitude, :producer_longitude, to: :product_sku
  delegate :client_full_name, to: :order
  delegate :latitude, :longitude, :project_name, :project_type,
           to: :tree_plantation, prefix: true, allow_nil: true

  scope :to_deliver_by_email, -> { where("delivery_email <> ''") }
  scope :certificable, lambda {
    includes(:certificate_attachment).select { |line_item| line_item.certificate.attached? }
  }

  def tree_marker
    {
      lat: tree_plantation_latitude.to_f,
      lng: tree_plantation_longitude.to_f,
      infoWindow: { content: "<h5>#{tree_plantation_project_name}</h5>\
      #{tree_plantation_project_type}" },
      icon: ActionController::Base.helpers.asset_path('tree_marker.png')
    }
  end

  def producer_marker
    {
      lat: producer_latitude.to_f,
      lng: producer_longitude.to_f,
      infoWindow: { content: "<h5>#{product_name}</h5>" },
      icon: ActionController::Base.helpers.asset_path('craftstore_marker.png')
    }
  end

  def tree_marker?
    tree_plantation_latitude && tree_plantation_longitude
  end

  def producer_marker?
    producer_latitude && producer_longitude
  end

  def added_quantity
    quantity - quantity_was
  end

  def update_price
    self.ttc_price_cents = quantity * product_ttc_price_cents
  end

  private

  def decrement_stock_quantities
    product_sku.decrement(:quantity, added_quantity) unless tree?
    tree_plantation.decrement(:quantity, added_quantity) unless classic?
  end
end
