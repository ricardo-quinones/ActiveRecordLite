class MassObject
  def self.my_attr_accessor(*names)
    names.each do |name|
      define_method(name) do
        instance_variable_get("@#{name}")
      end
      define_method("#{name}=") do |value|
        instance_variable_set("@#{name}", value)
      end
    end
  end

  def self.my_attr_accessible(*attributes)
    @attributes = attributes.map(&:to_sym)
    attributes.each do |attribute|
      MassObject.my_attr_accessor(attribute)
    end
  end

  def self.attributes
    @attributes
  end

  def self.parse_all(results)
  end


  def initialize(params = {})
    params.each do |attribute, value|
      attr_name = attribute.to_sym
      if self.class.attributes.include?(attr_name)
        self.send("#{attr_name}=", value)
      else
        raise "mass assignment to unregistered attribute '#{attribute}'"
      end
    end
  end
end

# class Cat < MassObject
#   my_attr_accessible :name, :gender
# end
#
# ikki = Cat.new({:name => "ikki", :gender => "male"})
#
# p ikki

# ikki.name = "thomas"
# ikki.gender = "male"
#
# p ikki.name
# p ikki.gender

# hash = {:name => "ikki"}
#
# hash.each do |attribute, value|
#   puts "true" if Cat.attributes.include?(attribute)
# end
#
