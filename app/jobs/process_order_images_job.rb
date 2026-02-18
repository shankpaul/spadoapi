class ProcessOrderImagesJob < ApplicationJob
  queue_as :default

  # Retry logic for transient failures
  retry_on ActiveStorage::IntegrityError, wait: 5.seconds, attempts: 3
  retry_on ActiveStorage::FileNotFoundError, wait: 5.seconds, attempts: 3

  def perform(order_id, attachment_type)
    order = Order.find(order_id)
    
    case attachment_type
    when 'before_images'
      process_images(order.before_images) if order.before_images.attached?
    when 'after_images'
      process_images(order.after_images) if order.after_images.attached?
    when 'customer_signature'
      process_signature(order.customer_signature) if order.customer_signature.attached?
    when 'payment_proof'
      process_signature(order.payment_proof) if order.payment_proof.attached?
    end
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error "Order #{order_id} not found: #{e.message}"
  rescue => e
    Rails.logger.error "Failed to process images for order #{order_id}: #{e.message}"
    raise # Re-raise to trigger retry logic
  end

  private

  def process_images(attachments)
    attachments = [attachments] unless attachments.respond_to?(:each)
    
    attachments.each do |attachment|
      next unless attachment.analyzed?
      
      # Generate variants for thumbnails
      attachment.variant(resize_to_limit: [800, 600]).processed
      attachment.variant(resize_to_limit: [200, 150]).processed # thumbnail
      
      Rails.logger.info "Processed image variants for attachment #{attachment.id}"
    end
  end

  def process_signature(attachment)
    return unless attachment.analyzed?
    
    # Generate smaller variant for signature
    attachment.variant(resize_to_limit: [400, 200]).processed
    
    Rails.logger.info "Processed signature variant for attachment #{attachment.id}"
  end
end
