namespace :subscriptions do
  desc "Generate orders for upcoming subscription washing dates (7 days ahead)"
  task generate_orders: :environment do
    puts "Starting subscription order generation at #{Time.current}"
    puts "=" * 60
    
    service = Subscriptions::OrderGeneratorService.new(7)
    result = service.generate_upcoming_orders
    
    puts "\nResults:"
    puts "  Generated: #{result[:generated_count]} orders"
    puts "  Errors: #{result[:errors].size}"
    
    if result[:errors].any?
      puts "\nErrors encountered:"
      result[:errors].each do |error|
        puts "  - Subscription ##{error[:subscription_id]}, Date: #{error[:scheduled_date]}"
        puts "    #{error[:errors].join(', ')}"
      end
    end
    
    puts "=" * 60
    puts "Completed at #{Time.current}"
  end

  desc "Check and expire subscriptions that have passed their end date"
  task expire_subscriptions: :environment do
    puts "Checking for expired subscriptions at #{Time.current}"
    puts "=" * 60
    
    expired_count = 0
    Subscription.where(status: [:scheduled, :active, :paused])
                .where('end_date < ?', Date.current)
                .find_each do |subscription|
      if subscription.may_expire? && subscription.expire!
        expired_count += 1
        puts "  Expired subscription ##{subscription.id} for customer: #{subscription.customer.name}"
      end
    end
    
    puts "\nExpired #{expired_count} subscriptions"
    puts "=" * 60
    puts "Completed at #{Time.current}"
  end

  desc "Send payment reminders for subscriptions with pending payments"
  task payment_reminders: :environment do
    puts "Checking for pending payments at #{Time.current}"
    puts "=" * 60
    
    subscriptions = Subscription.where(status: [:scheduled, :active, :paused])
                                .where(payment_status: [:pending, :failed])
    
    puts "Found #{subscriptions.count} subscriptions with pending/failed payments"
    
    subscriptions.find_each do |subscription|
      puts "  - Subscription ##{subscription.id}, Customer: #{subscription.customer.name}"
      puts "    Amount due: #{subscription.subscription_amount - subscription.payment_amount}"
      # TODO: Integrate with SMS/Email service to send reminders
    end
    
    puts "=" * 60
    puts "Completed at #{Time.current}"
  end

  desc "Run all subscription maintenance tasks"
  task maintenance: :environment do
    Rake::Task['subscriptions:generate_orders'].invoke
    Rake::Task['subscriptions:expire_subscriptions'].invoke
    Rake::Task['subscriptions:payment_reminders'].invoke
  end
end
