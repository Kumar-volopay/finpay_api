class AddFamilyIdToRefreshTokens < ActiveRecord::Migration[8.1]
  def up
    schemas = [ "public" ] + Company.pluck(:subdomain)

    schemas.uniq.each do |schema|
      next unless schema_exists?(schema)
      next unless data_source_exists?("#{schema}.refresh_tokens")

      table_name = "#{schema}.refresh_tokens"
      table = "#{connection.quote_table_name(schema)}.#{connection.quote_table_name('refresh_tokens')}"

      unless column_exists?(table_name, :family_id)
        add_column table_name, :family_id, :string
      end

      execute <<~SQL
        UPDATE #{table}
        SET family_id = gen_random_uuid()::text
        WHERE family_id IS NULL
      SQL

      change_column_null table_name, :family_id, false

      unless index_exists?(table_name, :family_id)
        add_index table_name, :family_id
      end
    end
  end

  def down
    schemas = [ "public" ] + Company.pluck(:subdomain)

    schemas.uniq.each do |schema|
      next unless schema_exists?(schema)
      next unless data_source_exists?("#{schema}.refresh_tokens")

      table_name = "#{schema}.refresh_tokens"

      if index_exists?(table_name, :family_id)
        remove_index table_name, :family_id
      end

      if column_exists?(table_name, :family_id)
        remove_column table_name, :family_id
      end
    end
  end
end
