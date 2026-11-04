class AddUserForeignKeyToRefreshTokens < ActiveRecord::Migration[8.1]
  def up
    table = :refresh_tokens

    return unless table_exists?(table)
    return unless table_exists?(:users)

    unless foreign_key_exists?(
      table,
      :users,
      column: :user_id
    )
      add_foreign_key(
        table,
        :users,
        column: :user_id
      )
    end
  end

  def down
    table = :refresh_tokens

    return unless table_exists?(table)

    if foreign_key_exists?(
      table,
      :users,
      column: :user_id
    )
      remove_foreign_key(
        table,
        :users,
        column: :user_id
      )
    end
  end
end
