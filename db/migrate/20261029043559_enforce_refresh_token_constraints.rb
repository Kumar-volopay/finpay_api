class EnforceRefreshTokenConstraints < ActiveRecord::Migration[8.1]
  def up
    schemas = [ "public" ] + Company.pluck(:subdomain)

    schemas.uniq.each do |schema|
      next unless schema_exists?(schema)
      next unless data_source_exists?("#{schema}.refresh_tokens")

      table = "#{connection.quote_table_name(schema)}.#{connection.quote_table_name('refresh_tokens')}"

      execute <<~SQL
        ALTER TABLE #{table}
          ALTER COLUMN user_id SET NOT NULL,
          ALTER COLUMN token_digest SET NOT NULL,
          ALTER COLUMN expires_at SET NOT NULL
      SQL

      execute <<~SQL
        CREATE UNIQUE INDEX IF NOT EXISTS index_refresh_tokens_on_token_digest
        ON #{table} (token_digest)
      SQL

      execute <<~SQL
        CREATE INDEX IF NOT EXISTS index_refresh_tokens_on_user_id
        ON #{table} (user_id)
      SQL
    end
  end

  def down
    schemas = [ "public" ] + Company.pluck(:subdomain)

    schemas.uniq.each do |schema|
      next unless schema_exists?(schema)
      next unless data_source_exists?("#{schema}.refresh_tokens")

      table = "#{connection.quote_table_name(schema)}.#{connection.quote_table_name('refresh_tokens')}"

      execute <<~SQL
        DROP INDEX IF EXISTS #{connection.quote_table_name(schema)}.#{connection.quote_table_name('index_refresh_tokens_on_token_digest')}
      SQL

      execute <<~SQL
        DROP INDEX IF EXISTS #{connection.quote_table_name(schema)}.#{connection.quote_table_name('index_refresh_tokens_on_user_id')}
      SQL

      execute <<~SQL
        ALTER TABLE #{table}
          ALTER COLUMN user_id DROP NOT NULL,
          ALTER COLUMN token_digest DROP NOT NULL,
          ALTER COLUMN expires_at DROP NOT NULL
      SQL
    end
  end
end
