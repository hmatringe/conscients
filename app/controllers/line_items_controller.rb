# frozen_string_literal: true

class LineItemsController < ApplicationController
  before_action :set_product, :set_product_sku
  respond_to :js, :html

  def create
    @line_item = AddItemToCart.new(@cart, line_item_params, params.dig(:line_item, :quantity))
                              .perform
    respond_with(@line_item, location: product_path(@product)) do |format|
      format.html { render 'products/show' } unless @line_item.save
    end
  end

  private

  def set_product
    @product = Product.with_attached_images.find(params[:product_id])
  end

  def set_product_sku
    @product_sku = @product.product_skus
                           .merge(skus_with_variants)
                           .first
  end

  def skus_with_variants
    product_skus = ProductSku.all
    params[:variants]&.each do |_, value|
      product_skus = product_skus.merge(product_skus_with_variant(get_variant(value)))
    end
    product_skus
  end

  def product_skus_with_variant(variant)
    ProductSku.with_variant(variant)
  end

  def get_variant(value)
    Variant.find(value)
  end

  def line_item_params
    params.require(:line_item).permit(:recipient_name, :recipient_message, :certificate_date)
          .merge(product_sku_id: @product_sku.id)
  end
end
