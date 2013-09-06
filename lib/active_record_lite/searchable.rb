require_relative './db_connection'

module Searchable
  def where(params)
    attr_names = params.keys.map { |key| "#{key} = ?" }
    DBConnection.execute(<<-SQL, *params.values)
    SELECT
      #{self.table_name}.*
    FROM
      #{self.table_name}
    WHERE
      #{attr_names.join(' AND ')}
    SQL
  end
end