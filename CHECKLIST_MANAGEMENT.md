# Packages and Checklist Management

This system allows you to manage packages and their associated checklist items through a JSON file and rake tasks.

## Files

- **config/packages_checklist.json** - Define packages and checklist items
- **lib/tasks/checklist.rake** - Rake tasks for syncing, exporting, and viewing data

## JSON File Structure

```json
{
  "checklist_items": [
    {
      "id": 1,
      "name": "Check tire pressure",
      "when": "pre",           // "pre" or "post"
      "active": true,
      "position": 1            // For ordering
    }
  ],
  "packages": [
    {
      "name": "Basic Wash - Hatchback",
      "vehicle_type": "hatchback",  // hatchback, sedan, suv, luxury
      "unit_price": 299,
      "active": true,
      "description": "Optional description",
      "checklist_item_ids": [1, 2, 3, 4, 5, 6, 7, 8]
    }
  ]
}
```

## Rake Tasks

### 1. Sync from JSON to Database

Reads the JSON file and creates or updates packages and checklist items.

```bash
cd spado-api
rails checklist:sync
```

**Features:**
- Creates new checklist items if ID doesn't exist
- Updates existing checklist items if data changes
- Creates new packages (by name and vehicle_type combination)
- Updates existing packages if data changes
- Manages package-checklist associations
- Shows detailed progress and summary

### 2. Export Database to JSON

Exports current database state to a JSON file for backup or editing.

```bash
rails checklist:export
```

Output: `config/packages_checklist_export.json`

### 3. Show Current State

Displays all packages and their associated checklist items in a readable format.

```bash
rails checklist:show
```

## Workflow

### Initial Setup

1. Edit `config/packages_checklist.json` with your desired configuration
2. Run `rails checklist:sync` to create packages and checklist items
3. Verify with `rails checklist:show`

### Making Changes

1. Edit `config/packages_checklist.json`:
   - Add new checklist items with unique IDs
   - Update existing items (keep same ID)
   - Add new packages
   - Update package prices or associations
   - Change active status to disable items/packages
2. Run `rails checklist:sync` to apply changes
3. Verify with `rails checklist:show`

### Backup Current State

```bash
rails checklist:export
```

This creates a backup of your current configuration that can be used to restore or share.

## Examples

### Adding a New Checklist Item

```json
{
  "id": 9,
  "name": "Check windshield wipers",
  "when": "pre",
  "active": true,
  "position": 5
}
```

### Creating a New Package

```json
{
  "name": "Deluxe Wash - Sedan",
  "vehicle_type": "sedan",
  "unit_price": 799,
  "active": true,
  "description": "Premium wash with waxing",
  "checklist_item_ids": [1, 2, 3, 4, 5, 6, 7, 8, 9]
}
```

### Disabling Items

Set `"active": false` to disable without deleting:

```json
{
  "id": 3,
  "name": "Check fuel level",
  "when": "pre",
  "active": false,
  "position": 3
}
```

### Changing Package Associations

Just modify the `checklist_item_ids` array and run sync:

```json
{
  "name": "Basic Wash - Hatchback",
  "vehicle_type": "hatchback",
  "unit_price": 299,
  "active": true,
  "checklist_item_ids": [1, 2, 5, 6, 7]  // Removed items 3, 4, 8
}
```

## Notes

- **Checklist Item IDs**: Must be unique. Use sequential numbering.
- **Package Identity**: Packages are identified by combination of `name` and `vehicle_type`
- **Safe Updates**: The sync task only updates what has changed
- **Associations**: Package-checklist associations are automatically managed
- **No Deletions**: The sync task doesn't delete items, only creates/updates and manages associations

## Order API Integration

When agents view orders, they automatically get checklist items from all packages in the order, grouped by pre/post work:

```json
GET /api/v1/orders/:id

{
  "checklist": {
    "pre": [...],   // All pre-work items from order packages
    "post": [...]   // All post-work items from order packages
  }
}
```
