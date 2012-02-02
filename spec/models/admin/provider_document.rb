module Admin
  class ProviderDocument

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
      :dataset => lambda do |admin_provider_document|
        {
          0 => "<%= link_to(admin_provider_document.name, '#') %>",
          1 => admin_provider_document.fein,
          2 => admin_provider_document.category.name,
          3 => admin_provider_document.country,
          4 => admin_provider_document.state,
          :DT_RowId => admin_provider_document._id
        }
      end
    })

  end
end