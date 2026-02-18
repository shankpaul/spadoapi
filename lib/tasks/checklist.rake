namespace :checklist do
  desc "Sync packages and checklist items from JSON file"
  task sync: :environment do
    puts "Starting sync of packages and checklist items..."
    
    # Load JSON file
    json_file = Rails.root.join('config', 'packages_checklist.json')
    
    unless File.exist?(json_file)
      puts "Error: JSON file not found at #{json_file}"
      exit 1
    end
    
    data = JSON.parse(File.read(json_file))
    
    # Track statistics
    stats = {
      checklist_created: 0,
      checklist_updated: 0,
      packages_created: 0,
      packages_updated: 0,
      associations_added: 0
    }
    
    # Sync checklist items
    puts "\n=== Syncing Checklist Items ==="
    data['checklist_items'].each do |item_data|
      checklist_item = ChecklistItem.find_or_initialize_by(id: item_data['id'])
      
      is_new = checklist_item.new_record?
      
      checklist_item.assign_attributes(
        name: item_data['name'],
        when: item_data['when'],
        active: item_data['active'],
        position: item_data['position']
      )
      
      if checklist_item.changed?
        if checklist_item.save
          if is_new
            stats[:checklist_created] += 1
            puts "  ✓ Created: #{checklist_item.name} (#{checklist_item.when})"
          else
            stats[:checklist_updated] += 1
            puts "  ↻ Updated: #{checklist_item.name} (#{checklist_item.when})"
          end
        else
          puts "  ✗ Error saving #{item_data['name']}: #{checklist_item.errors.full_messages.join(', ')}"
        end
      else
        puts "  - Unchanged: #{checklist_item.name}"
      end
    end
    
    # Sync packages
    puts "\n=== Syncing Packages ==="
    data['packages'].each do |pkg_data|
      # Find package by name and vehicle type (composite key)
      package = Package.unscoped.find_or_initialize_by(
        name: pkg_data['name'],
        vehicle_type: pkg_data['vehicle_type']
      )
      
      is_new = package.new_record?
      
      package.assign_attributes(
        unit_price: pkg_data['unit_price'],
        active: pkg_data['active'],
        description: pkg_data['description']
      )
      
      # Save package first
      if package.changed?
        if package.save
          if is_new
            stats[:packages_created] += 1
            puts "  ✓ Created: #{package.name}"
          else
            stats[:packages_updated] += 1
            puts "  ↻ Updated: #{package.name}"
          end
        else
          puts "  ✗ Error saving #{pkg_data['name']}: #{package.errors.full_messages.join(', ')}"
          next
        end
      else
        puts "  - Unchanged: #{package.name}"
      end
      
      # Sync checklist item associations
      if pkg_data['checklist_item_ids'].present?
        checklist_item_ids = pkg_data['checklist_item_ids']
        current_ids = package.checklist_item_ids.sort
        desired_ids = checklist_item_ids.sort
        
        if current_ids != desired_ids
          # Find items to add and remove
          to_add = desired_ids - current_ids
          to_remove = current_ids - desired_ids
          
          # Add new associations
          to_add.each do |checklist_id|
            item = ChecklistItem.find_by(id: checklist_id)
            if item
              package.checklist_items << item unless package.checklist_items.include?(item)
              stats[:associations_added] += 1
              puts "    + Added checklist: #{item.name}"
            else
              puts "    ✗ Checklist item ##{checklist_id} not found"
            end
          end
          
          # Remove old associations
          to_remove.each do |checklist_id|
            item = ChecklistItem.find_by(id: checklist_id)
            if item
              package.checklist_items.delete(item)
              puts "    - Removed checklist: #{item.name}"
            end
          end
        end
      end
    end
    
    # Print summary
    puts "\n=== Sync Summary ==="
    puts "Checklist Items:"
    puts "  Created: #{stats[:checklist_created]}"
    puts "  Updated: #{stats[:checklist_updated]}"
    puts "\nPackages:"
    puts "  Created: #{stats[:packages_created]}"
    puts "  Updated: #{stats[:packages_updated]}"
    puts "\nAssociations:"
    puts "  Modified: #{stats[:associations_added]}"
    puts "\n✓ Sync completed successfully!"
  end
  
  desc "Export current packages and checklist items to JSON"
  task export: :environment do
    puts "Exporting packages and checklist items to JSON..."
    
    # Export checklist items
    checklist_items = ChecklistItem.all.map do |item|
      {
        id: item.id,
        name: item.name,
        when: item.when,
        active: item.active,
        position: item.position
      }
    end
    
    # Export packages
    packages = Package.all.map do |pkg|
      {
        name: pkg.name,
        vehicle_type: pkg.vehicle_type,
        unit_price: pkg.unit_price.to_f,
        active: pkg.active,
        description: pkg.description,
        checklist_item_ids: pkg.checklist_item_ids.sort
      }
    end
    
    data = {
      checklist_items: checklist_items,
      packages: packages
    }
    
    output_file = Rails.root.join('config', 'packages_checklist_export.json')
    File.write(output_file, JSON.pretty_generate(data))
    
    puts "✓ Exported to #{output_file}"
    puts "  Checklist Items: #{checklist_items.count}"
    puts "  Packages: #{packages.count}"
  end
  
  desc "Show current packages and their checklist items"
  task show: :environment do
    puts "=== Packages and Checklist Items ==="
    
    Package.includes(:checklist_items).each do |package|
      puts "\n#{package.name} (#{package.vehicle_type}) - ₹#{package.unit_price}"
      puts "  Status: #{package.active? ? 'Active' : 'Inactive'}"
      
      if package.checklist_items.any?
        puts "  Checklist Items:"
        
        pre_items = package.checklist_items.where(when: 'pre').ordered
        if pre_items.any?
          puts "    Pre-work:"
          pre_items.each do |item|
            puts "      #{item.position}. #{item.name}"
          end
        end
        
        post_items = package.checklist_items.where(when: 'post').ordered
        if post_items.any?
          puts "    Post-work:"
          post_items.each do |item|
            puts "      #{item.position}. #{item.name}"
          end
        end
      else
        puts "  No checklist items assigned"
      end
    end
  end
end
