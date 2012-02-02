# Mongoid: Data Table

[![Build Status](https://secure.travis-ci.org/potatosalad/mongoid-data_table.png)](http://travis-ci.org/potatosalad/mongoid-data_table)

[![Dependency Status](https://gemnasium.com/potatosalad/mongoid-data_table.png?travis)](https://gemnasium.com/potatosalad/mongoid-data_table)

Makes it easy to ship data to a jQuery DataTable from Mongoid.

## Quick example:

### Javascript

```javascript
$(".providers-data-table").dataTable({
  "bJQueryUI"       : true,
  "bProcessing"     : true,
  "bAutoWidth"      : false,
  "sPaginationType" : "full_numbers",
  "aoColumns"       : [{"sType" : "html"}, null, null, null, null],
  "aaSorting"       : [[0, 'asc'], [1, 'asc']],
  "bServerSide"     : true,
  "sAjaxSource"     : "/providers.json"
}).fnSetFilteringDelay();
```

**Note:** the fnSetFilteringDelay() call isn't required but highly recommended: http://datatables.net/plug-ins/api#fnSetFilteringDelay

### Model

```ruby
class Provider

  include Mongoid::Documenta
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
        0 => "<%= link_to(provider.name, provider) %>",
        1 => provider.fein,
        2 => provider.category.name,
        3 => provider.country,
        4 => provider.state,
        :DT_RowId => provider._id
      }
    end
  })

end
```

### Controller (InheritedResources::Base)

**Recommended:** https://github.com/josevalim/inherited_resources

```ruby
class PrividersController < InheritedResources::Base

  respond_to :json, :only => :index

  protected

  def collection
    @providers ||= end_of_association_chain.to_data_table(self)
  end

end
```

### Controller (ActionController::Base)

```ruby
class ProvidersController < ApplicationController

  def index
    respond_to do |format|
      format.html
      format.json do
        render :json => Provider.to_data_table(self)
      end
    end
  end

end
```

### View (HAML)

```haml
%table.providers-data-table
  %thead
    %tr
      %th Name
      %th FEIN
      %th Category
      %th County
      %th State

  %tbody
```

Patches welcome, enjoy!

## Copyright

Copyright &copy; 2010-2011 Jason Dew, Andrew Bennett. See LICENSE for details.
