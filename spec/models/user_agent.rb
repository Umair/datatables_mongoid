class UserAgent
  include Mongoid::Document
  include Mongoid::DataTable

  field :engine
  field :name
  field :platforms, :type => Array
  field :version, :type => Float
  field :grade

  validates_inclusion_of :grade, :in => ('A'..'Z')
end