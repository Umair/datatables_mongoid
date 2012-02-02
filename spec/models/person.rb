class Person
  include Mongoid::Document
  include Mongoid::DataTable

  field :name
  field :_type # destrustive_field
end