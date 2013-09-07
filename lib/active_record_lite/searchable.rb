require_relative './db_connection'

module Searchable
  def where(params)
    attr_names = params.keys.map { |key| "#{key} = ?" }
    results = DBConnection.execute(<<-SQL, *params.values)
    SELECT
      #{self.table_name}.*
    FROM
      #{self.table_name}
    WHERE
      #{attr_names.join(' AND ')}
    SQL

    parse_all(results)
  end
end