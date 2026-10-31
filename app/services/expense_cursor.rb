
# frozen_string_literal: true

class ExpenseCursor
  def self.encode(expense)
    cursor_data = {
      created_at: expense.created_at.iso8601(6),
      id: expense.id
    }

    Base64.urlsafe_encode64(cursor_data.to_json, padding: false)
  end

  def self.decode(cursor)
    decoded = Base64.urlsafe_decode64(cursor)
    data = JSON.parse(decoded)

    created_at = Time.iso8601(data.fetch("created_at"))
    id = Integer(data.fetch("id"))

    raise ArgumentError, "Invalid cursor" unless id.positive?

    {
      created_at: created_at,
      id: id
    }
  rescue ArgumentError, KeyError, JSON::ParserError, TypeError
    raise ArgumentError, "Invalid cursor"
  end

  def self.apply(scope, cursor)
    position = decode(cursor)

    scope.where(
      "created_at < :created_at OR (created_at = :created_at AND id < :id)",
      created_at: position[:created_at],
      id: position[:id]
    )
  end
end
