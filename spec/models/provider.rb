class Provider

  include Mongoid::Document
  include Mongoid::DataTable

  ## fields ##
  field :name
  field :fein
  field :country
  field :state

  ## associations ##
  referenced_in :category

  ## data_table ##
  data_table_options.merge!({
    :fields => %w(name fein category country state),
    :searchable => %w(name fein),
    :dataset => lambda do |provider|
      {
        0 => "<%= link_to(provider.name, '#') %>",
        1 => provider.fein,
        2 => provider.category.name,
        3 => provider.country,
        4 => provider.state,
        :DT_RowId => provider._id
      }
    end
  })

end