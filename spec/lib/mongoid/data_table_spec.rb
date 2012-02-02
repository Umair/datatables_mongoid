require 'spec_helper'

describe Mongoid::DataTable do

  before do
    Person.delete_all
  end

  context "on a default document" do

    describe ".data_table_options" do

      it "defaults to a hash" do
        Person.data_table_options.should be_a(Hash)
      end

    end

    describe ".data_table_options" do

      it "defaults to a hash" do
        Person.data_table_options.should be_a(Hash)
      end

    end

    describe ".data_table_fields" do

      it "defaults to already defined fields" do
        (Person.fields.keys & Person.data_table_fields).should have(Person.data_table_fields.length).items
      end

      it "should not include Mongoid.destructive_fields" do
        Person.data_table_fields.should_not include(*Mongoid.destructive_fields)
      end

    end

    describe ".data_table_searchable_fields" do

      it "defaults to .data_table_fields" do
        Person.data_table_searchable_fields.should == Person.data_table_fields
      end

    end

    describe ".data_table_sortable_fields" do

      it "defaults to .data_table_fields" do
        Person.data_table_sortable_fields.should == Person.data_table_fields
      end

    end

    describe ".to_data_table" do

      before do
        Rails.stubs(:logger).returns(LOGGER)
      end

      let(:bob) do
        Person.find_or_create_by(:name => 'Bob')
      end

      let(:controller) do
        Class.new(ActionController::Base).new.tap do |c|
          c.stubs(:cookies).returns({})
          c.stubs(:params).returns({})
        end
      end

      it "should create a Mongoid::DataTable::Proxy object" do
        Person.to_data_table(controller).__metaclass__.superclass.should == ::Mongoid::DataTable::Proxy
      end

      describe "#to_hash" do

        let(:dt) do
          bob
          Person.to_data_table(controller)
        end

        it "should be a Hash" do
          dt.to_hash.should be_a(Hash)
        end

        it "should be formatted for DataTables" do
          dt.to_hash.keys.should include(:sEcho, :iTotalRecords, :iTotalDisplayRecords, :aaData)
        end

        it "should include DT_RowId" do
          result = dt.to_hash[:aaData].first
          result.keys.should include('DT_RowId')
        end

        context "with inline block" do

          it "should run inline block (Array)" do
            result = dt.to_hash do |person|
              [ person.name ]
            end[:aaData].first
            result.should be_a(Array)
            result.first.should == bob.name
          end

          it "should run inline block (Hash)" do
            result = dt.to_hash do |person|
              { :name => person.name }
            end[:aaData].first
            result.should be_a(Hash)
            result['name'].should == bob.name
          end

        end

      end

      context "with inline block (Array)" do

        let(:dt) do
          bob
          Person.to_data_table(controller) do |person|
            [ person.name ]
          end
        end

        describe "#to_hash" do

          it "should be a Hash" do
            dt.to_hash.should be_a(Hash)
          end

          it "should be formatted for DataTables" do
            dt.to_hash.keys.should include(:sEcho, :iTotalRecords, :iTotalDisplayRecords, :aaData)
          end

          it "should run inline block" do
            result = dt.to_hash[:aaData].first
            result.should be_a(Array)
            result.first.should == bob.name
          end

        end

      end

    end

  end

end