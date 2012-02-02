class Category

  include Mongoid::Document

  ## fields ##
  field :name

  ## associations ##
  references_many :providers

end