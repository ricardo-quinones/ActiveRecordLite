require 'active_support/core_ext/object/try'
require 'active_support/inflector'
require_relative './db_connection.rb'

class AssocParams
  attr_reader :other_class_name, :primary_key, :foreign_key

  def other_class
    @other_class_name.constantize
  end

  def other_table
    other_class.table_name
  end
end

class BelongsToAssocParams < AssocParams
  def initialize(name, params)
    @other_class_name = params[:class_name] || name.to_s.camelize
    @primary_key = params[:primary_key] || :id
    @foreign_key = params[:foreign_key] || "#{name}_id".to_sym
  end

  def type
    :belongs_to
  end
end

class HasManyAssocParams < AssocParams
  def initialize(name, params, self_class)
    @other_class_name = params[:class_name] ||
      name.to_s.singularize.camelize
    @primary_key = params[:primary_key] || :id
    @foreign_key = params[:foreign_key] ||
      "#{self_class.name.underscore}_id"
  end

  def type
    :has_many
  end
end

module Associatable

  def assoc_params
    @assoc_params ||= {}
    @assoc_params
  end

  def belongs_to(name, params = {})
    aps = BelongsToAssocParams.new(name, params)
    self.assoc_params[name] = aps

    define_method(name) do
      results = DBConnection.execute(<<-SQL, self.send(aps.foreign_key))
        SELECT
          #{aps.other_table}.*
        FROM
          #{aps.other_table}
        WHERE
          #{aps.other_table}.#{aps.primary_key} = ?
      SQL

      aps.other_class.parse_all(results).first
    end
  end

  def has_many(name, params = {})
    aps = HasManyAssocParams.new(name, params, self.class)

    define_method(name) do
      results = DBConnection.execute(<<-SQL, self.send(aps.primary_key))
        SELECT
          #{aps.other_table}.*
        FROM
          #{aps.other_table}
        WHERE
          #{aps.other_table}.#{aps.foreign_key} = ?
      SQL

      aps.other_class.parse_all(results)
    end
  end

  def has_one_through(name, assoc1, assoc2)
    define_method(name) do
      aps1 = self.class.assoc_params[assoc1]
      aps2 = aps1.other_class.assoc_params[assoc2]
      
      results = DBConnection.execute(<<-SQL, self.send(aps1.foreign_key))
        SELECT
          house.*
        FROM
          #{aps2.other_table} AS house
        JOIN
          #{aps1.other_table} AS human
        ON human.#{aps2.foreign_key} = house.#{aps2.primary_key}
        WHERE
          human.#{aps1.primary_key} = ?
      SQL
      
      aps2.other_class.parse_all(results).first
    end
  end
end
