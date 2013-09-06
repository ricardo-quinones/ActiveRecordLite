require 'active_support/inflector'

require_relative './associatable'
require_relative './db_connection'
require_relative './mass_object'
require_relative './searchable'

class SQLObject < MassObject
  extend Searchable

  def self.set_table_name(table_name)
    name = table_name.pluralize
    @table_name = name.underscore
  end

  def self.table_name
    @table_name
  end

  def self.all
    results = DBConnection.execute(<<-SQL)
      SELECT
        "#{table_name}".*
      FROM
        "#{table_name}"
    SQL

    results
  end

  def self.find(id)
    results = DBConnection.execute(<<-SQL, id)
      SELECT
        "#{table_name}".*
      FROM
        "#{table_name}"
      WHERE
        "#{table_name}".id = ?
    SQL

    results.empty? ? nil : self.new(results.first)
  end

  def save
    if self.id == nil
      create
    else
      update
    end
  end

 #  private
  def attribute_values
    self.class.attributes.drop(1).map { |attr_name| self.send("#{attr_name}") }
  end

  def create
    num = attribute_values.length
    DBConnection.execute(<<-SQL, *attribute_values)
    INSERT INTO
      #{self.class.table_name} (#{self.class.attributes.drop(1).join(', ')})
    VALUES
      (#{(['?'] * num).join(', ')})
    SQL
    self.id = DBConnection.last_insert_row_id
  end

  def update
    set_line = self.class.attributes.drop(1).map { |attr_name| "#{attr_name} = ?"}.join(", ")
    DBConnection.execute(<<-SQL, *attribute_values)
    UPDATE
      #{self.class.table_name}
    SET
      #{set_line}
    WHERE
      #{self.class.table_name}.id = #{self.id}
    SQL
  end
end
