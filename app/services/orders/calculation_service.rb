module Orders
  class CalculationService
    attr_reader :order

    def initialize(order)
      @order = order
    end

    def self.call(order)
      new(order).calculate
    end

    def calculate
      return false unless order

      subtotal = calculate_subtotal
      gst_amount = calculate_gst(subtotal)
      total_amount = (subtotal + gst_amount).round(2)

      order.update(
        gst_amount: gst_amount,
        total_amount: total_amount
      )
    end

    def recalculate!
      calculate
    end

    private

    def calculate_subtotal
      packages_total = order.order_packages.sum(:total_price)
      addons_total = order.order_addons.sum(:total_price)
      (packages_total + addons_total).round(2)
    end

    def calculate_gst(subtotal)
      gst_percentage = order.gst_percentage || 0
      (subtotal * gst_percentage / 100).round(2)
    end
  end
end
