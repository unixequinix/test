class AddRoleToAdmins < ActiveRecord::Migration[5.0]
  def change
    add_column :admins, :role, :integer, default: 3
  end
end
