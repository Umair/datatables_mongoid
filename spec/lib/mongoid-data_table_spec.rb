require 'spec_helper'

describe 'mongoid-data_table' do

  let(:category) do
    Category.find_or_create_by(:name => 'my_category')
  end

  let(:provider) do
    Provider.find_or_create_by({
      :name => 'my_name',
      :fein => 'my_fein',
      :country => 'my_country',
      :state => 'my_state',
      :category_id => category.id
    })
  end

  before do
    Rails.stubs(:logger).returns(LOGGER)
  end

  let(:controller) do
    Class.new(ActionController::Base).new.tap do |c|
      c.stubs(:cookies).returns({})
      c.stubs(:params).returns({})
    end
  end

  context "when using example from README" do

    def sample_data(id)
      {
        "sEcho" => 0,
        "iTotalRecords" => 1,
        "iTotalDisplayRecords" => 1,
        "aaData" => [{
          "0" => "<a href=\"#\">my_name</a>",
          "1" => "my_fein",
          "2" => "my_category",
          "3" => "my_country",
          "4" => "my_state",
          "DT_RowId" => id.to_s
        }]
      }
    end

    it "should return sample data" do
      provider.category.should == category
      JSON.load(Provider.where(:name => 'my_name').to_data_table(controller).to_json).should == sample_data(provider.id)
    end

    context "with inline block" do

      def custom_sample_data(id)
      {
        "sEcho" => 0,
        "iTotalRecords" => 1,
        "iTotalDisplayRecords" => 1,
        "aaData" => [[id.to_s]]
      }
    end

      it "should return sample data" do
        provider.category.should == category
        JSON.load(Provider.where(:name => 'my_name').to_data_table(controller).to_json do |provider|
          [ provider.id ]
        end).should == custom_sample_data(provider.id)
      end

    end

  end

  ## namespaced test ##

  let(:admin_provider_document) do
    Admin::ProviderDocument.find_or_create_by({
      :name => 'admin_name',
      :fein => 'admin_fein',
      :country => 'admin_country',
      :state => 'admin_state',
      :category_id => category.id
    })
  end

  context "when using namespaced example from README" do

    def sample_data(id)
      {
        "sEcho" => 0,
        "iTotalRecords" => 1,
        "iTotalDisplayRecords" => 1,
        "aaData" => [{
          "0" => "<a href=\"#\">admin_name</a>",
          "1" => "admin_fein",
          "2" => "my_category",
          "3" => "admin_country",
          "4" => "admin_state",
          "DT_RowId" => id.to_s
        }]
      }
    end

    it "should return sample data" do
      admin_provider_document.category.should == category
      JSON.load(Admin::ProviderDocument.where(:name => 'admin_name').to_data_table(controller).to_json).should == sample_data(admin_provider_document.id)
    end

    context "with inline block" do

      def custom_sample_data(id)
      {
        "sEcho" => 0,
        "iTotalRecords" => 1,
        "iTotalDisplayRecords" => 1,
        "aaData" => [[id.to_s]]
      }
    end

      it "should return sample data" do
        admin_provider_document.category.should == category
        JSON.load(Admin::ProviderDocument.where(:name => 'admin_name').to_data_table(controller).to_json do |admin_provider_document|
          [ admin_provider_document.id ]
        end).should == custom_sample_data(admin_provider_document.id)
      end

    end

  end

end