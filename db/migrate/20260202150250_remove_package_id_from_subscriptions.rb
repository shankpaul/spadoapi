class RemovePackageIdFromSubscriptions < ActiveRecord::Migration[8.0]
  def change
    remove_reference :subscriptions, :package, foreign_key: true, index: true
  end
end
