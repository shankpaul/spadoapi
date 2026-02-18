class AddOfficeToUsers < ActiveRecord::Migration[8.0]
  def change
    add_reference :users, :office, foreign_key: true
  end
end
