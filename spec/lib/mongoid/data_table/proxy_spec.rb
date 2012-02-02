require 'spec_helper'

describe Mongoid::DataTable::Proxy do

  before do
    Rails.stubs(:logger).returns(LOGGER)
  end

  let(:controller) do
    Class.new(ActionController::Base).new.tap do |c|
      c.stubs(:cookies).returns({})
      c.stubs(:params).returns({})
    end
  end

  let(:custom_array) { %w(custom) }

  let(:custom_block) do
    lambda { |object| custom_array }
  end

  describe "#new" do

    it "creates a new Mongoid::DataTable::Proxy object" do
      proxy = Mongoid::DataTable::Proxy.new(Person, controller)
      proxy.__metaclass__.superclass.should == Mongoid::DataTable::Proxy
    end

  end

  context "with default settings" do

    let(:proxy) do
      bob
      Mongoid::DataTable::Proxy.new(Person, controller)
    end

    let(:bob) do
      Person.find_or_create_by(:name => 'Bob')
    end

    let(:sam) do
      Person.find_or_initialize_by(:name => 'Sam')
    end

    describe "#collection" do

      it "should be paged to page 1" do
        proxy.collection.current_page.should == proxy.current_page
      end

      it "should reload when passed true" do
        proxy.collection.should include(bob)
        proxy.collection.should_not include(sam)
        sam.save
        proxy.collection(true).should include(sam)
        sam.destroy
      end

    end

    describe "#current_page" do

      it "should default to 1" do
        proxy.current_page.should be(1)
      end

    end

    describe "#per_page" do

      it "should default to 10" do
        proxy.per_page.should be(10)
      end

    end

  end

  context "with custom block" do

    let(:bob) do
      Person.find_or_create_by(:name => 'Bob')
    end

    let(:dt) do
      bob
      Person.criteria.to_data_table(controller, {}, &custom_block)
    end

    it "should store it as an @extension" do
      dt.extension.should == custom_block
    end

    describe "#to_hash" do

      it "should run the custom block" do
        dt.to_hash[:aaData].first.should == custom_array
      end

      context "with inline block" do

        it "should run the inline block" do
          a = custom_array.push('inline')
          h = dt.to_hash { |object| a }
          h[:aaData].first.should == a
        end

      end

    end

  end

end