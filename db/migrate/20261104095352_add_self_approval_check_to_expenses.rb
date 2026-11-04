class AddSelfApprovalCheckToExpenses < ActiveRecord::Migration[8.1]
  def change
    add_check_constraint :expenses,
                         "approved_by_id IS DISTINCT FROM user_id",
                         name: "expenses_prevent_self_approval",
                         validate: false
  end
end
