namespace :users do
  desc "Expire inactive user accounts"
  task expire_inactive: :environment do
    count = 0
    User.find_each do |user|
      if user.check_and_expire_if_inactive!
        count += 1
        puts "Expired user: #{user.email} (ID: #{user.id})"
      end
    end
    puts "Total accounts expired: #{count}"
  end

  desc "Unlock accounts locked for more than configured duration"
  task unlock_temporary: :environment do
    count = 0
    User.where.not(locked_at: nil).find_each do |user|
      unless user.permanent_lock?
        if user.locked_at < User::ACCOUNT_LOCK_DURATION.ago
          user.unlock_account!
          count += 1
          puts "Unlocked user: #{user.email} (ID: #{user.id})"
        end
      end
    end
    puts "Total accounts unlocked: #{count}"
  end

  desc "Report on user account statuses"
  task report: :environment do
    total = User.count
    locked = User.where.not(locked_at: nil).count
    expired = User.where.not(expires_at: nil).where('expires_at <= ?', Time.current).count
    inactive = User.where('last_activity_at < ?', 30.days.ago).count

    puts "\n=== User Account Status Report ==="
    puts "Total users: #{total}"
    puts "Locked accounts: #{locked}"
    puts "Expired accounts: #{expired}"
    puts "Inactive (30+ days): #{inactive}"
    puts "==================================\n"
  end
end
