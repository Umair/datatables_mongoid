require 'json'
require 'uri'

module Mongoid
  module DataTable
    class Proxy < ::Mongoid::Relations::Proxy

      undef_method(:respond_to?) # Since mongoid 2.1.5, this messes up "render @objects.to_data_table(controller)"

      attr_reader :klass,
        :controller,
        :cookies,
        :raw_cookie,
        :cookie,
        :cookie_prefix,
        :options,
        :extension,
        :params,
        :criteria,
        :unscoped,
        :fields,
        :aliases,
        :locals

      def initialize(klass, controller, options = {}, &block)
        @klass      = klass
        @controller = controller
        @cookies    = @controller.send(:cookies)
        @options    = klass.data_table_options.merge(options)
        @extension  = block || options[:dataset] || klass.data_table_dataset || default_data_table_dataset

        @params   = (options[:params]  || controller.params || {}).dup.symbolize_keys
        @criteria = options[:criteria] || klass.criteria
        @unscoped = options[:unscoped] || klass.unscoped
        @fields   = options[:fields]   || klass.data_table_fields
        @aliases  = options[:aliases]  || @fields

        @locals = options[:locals] || {}

        params[:iDisplayLength] = conditions.count if (params[:iDisplayLength].to_i rescue 0) == -1

        @cookie_prefix = options[:cookie_prefix] || 'SpryMedia_DataTables_'
      end

      def collection(force = false)
        reload if force
        @collection ||= conditions
      end

      def reload
        (@collection = nil).nil?
      end

      def cookie(sInstance = nil)
        @cookie ||= load_cookie!(sInstance)
      end

      def cookie!(sInstance = nil)
        @cookie = nil
        sInstance ||= options[:sInstance]
        @raw_cookie = cookies[cookie_name(sInstance)]
        begin
          @cookie = ::JSON.load(raw_cookie) if raw_cookie.kind_of?(String)
        rescue JSON::ParserError
          cookies.delete cookie_name(sInstance)
          @cookie = {}
        ensure
          (@cookie ||= {}).symbolize_keys!
        end
      end

      def load_cookie!(sInstance = nil)
        tap do

          cookie!(sInstance)

          if cookie.present? and cookie.kind_of?(Hash)
            load_defaults!(cookie)
          elsif (defaults = options[:defaults]).present? and defaults.kind_of?(Hash)
            load_defaults!(defaults)
          end

        end
      end

      def load_defaults!(defaults = {})
        tap do
          state_params = Hash.new.tap do |hash|
            hash[:iDisplayStart]  = defaults[:iStart]  if defaults.has_key?(:iStart)
            hash[:iDisplayLength] = defaults[:iLength] if defaults.has_key?(:iLength)
            hash[:sSearch]        = defaults[:sFilter] if defaults.has_key?(:sFilter)

            if defaults.has_key?(:aaSorting)
              sorting = [*defaults[:aaSorting]].first

              hash[:iSortCol_0] = [*sorting][0]
              hash[:sSortDir_0] = [*sorting][1]
            end

            if defaults.has_key?(:aoSearchCols)
              [*defaults[:aoSearchCols]].each_with_index do |oSearch, index|
                if oSearch.kind_of?(Hash)
                  oSearch.symbolize_keys!
                  hash[:"bRegex_#{index}"]  = oSearch[:bRegex]
                  hash[:"sSearch_#{index}"] = URI.decode(oSearch[:sSearch])
                else
                  hash[:"sSearch_#{index}"] = URI.decode(oSearch.to_s)
                end
              end
            elsif defaults.has_key?(:aaSearchCols)
              begin
                [*defaults[:aaSearchCols]].each_with_index do |(value,regex),index|
                  hash[:"bRegex_#{index}"]  = !regex
                  hash[:"sSearch_#{index}"] = URI.decode(value)
                end
              rescue
                # do nothing
              end
            end
          end

          params.merge!(state_params)

          @collection = nil
        end
      end

      def search_fields
        return [] if cookie.blank? or not cookie.kind_of?(Hash)
        [].tap do |array|

          if cookie.has_key?(:aoSearchCols)
            [*cookie[:aoSearchCols]].each_with_index do |oSearch, index|
              if oSearch.kind_of?(Hash)
                oSearch.symbolize_keys!
                array.push(URI.decode(oSearch[:sSearch].to_s))
              end
            end
          else
            begin
              [*cookie[:aaSearchCols]].each_with_index do |(value,regex),index|
                array.push(URI.decode(value.to_s))
              end
            rescue
              # do nothing
            end
          end

        end
      end

      ## pagination options ##

      def current_page
        params[:page].present? ? params[:page].to_i : (params[:iDisplayStart].to_i/params[:iDisplayLength].to_i rescue 0)+1
      end

      def per_page
        (params[:iDisplayLength] || options[:per_page] || klass.per_page rescue 10).to_i
      end

      def conditions
        criteria.order_by(order_by_conditions).where(filter_conditions).where(filter_field_conditions).limit(per_page.to_i*current_page)
      end

      def to_hash(&inline_block)
        inline_block = extension unless block_given?
        {
          :sEcho => params[:sEcho].to_i,
          :iTotalRecords => unscoped.count,
          :iTotalDisplayRecords => conditions.count,
          :aaData => collection.map do |object|
            data = controller.instance_eval { inline_block.call(object) }
            data.inject(data.is_a?(Hash) ? {} : []) do |result, item|
              Rails.logger.silence_warnings do
                controller.instance_eval(&render_data_table_block(klass, item, object, result))
              end
            end
          end
        }
      end

      def as_json(options = nil, &inline_block)
        to_hash(&inline_block).to_json(options)
      end

      def to_json(*args, &inline_block)
        as_json(*args, &inline_block)
      end

      protected

      def order_by_conditions
        order_params = params.dup.select { |k,v| k.to_s =~ /(i|s)Sort(Col|Dir)_\d+/ }
        return options[:order_by] || [] if order_params.blank?
        order_params.select { |k,v| k.to_s =~ /iSortCol_\d+/ }.sort_by(&:first).map do |col,field|
          i = /iSortCol_(\d+)/.match(col.to_s)[1]
          [ fields[field.to_i], order_params[:"sSortDir_#{i}"] || :asc ]
        end
      end

      def filter_conditions
        return unless (query = params[:sSearch]).present?

        b_regex = Mongoid::Serialization.mongoize(params[:bRegex], Boolean)

        {
          "$or" => klass.data_table_searchable_fields.map { |field|
            { field => (b_regex === true) ? data_table_regex(query) : query }
          }
        }
      end

      def filter_field_conditions
        params.dup.select { |k,v| k.to_s =~ /sSearch_\d+/ }.inject({}) do |h,(k,v)|
          i = /sSearch_(\d+)/.match(k.to_s)[1]

          field_name = fields[i.to_i]
          #field = klass.fields.dup[field_name]
          #field_type = field.respond_to?(:type) ? field.type : Object

          query = params[:"sSearch_#{i}"]
          b_regex = Mongoid::Serialization.mongoize(params[:"bRegex_#{i}"], Boolean)

          h[field_name] = (b_regex === true) ? data_table_regex(query) : query if query.present?
          h
        end
      end

      private

      def cookie_name(sInstance)
        "#{cookie_prefix}#{sInstance}"
      end

      def default_data_table_dataset
        lambda do |object|
          Hash[aliases.map { |c| [ aliases.index(c), object.send(c) ] }].merge(:DT_RowId => object._id)
        end
      end

      def render_data_table_block(klass, item, object, result = [])
        data_table = self
        lambda do |base|
          if result.is_a?(Hash)
            result.store(*(item.map do |value|
              self.instance_eval(&data_table.send(:render_data_table_block, klass, value, object, ''))
            end))
          else
            result << render_to_string(:inline => item.to_s, :locals => data_table.locals.reverse_merge(:"#{klass.name.underscore.parameterize('_')}" => object, :object => object))
          end
          result
        end
      end

      def data_table_regex(query)
        Regexp.new(query, Regexp::IGNORECASE)
      rescue RegexpError
        Regexp.new(Regexp.escape(query), Regexp::IGNORECASE)
      end

      def method_missing(method, *args, &block) #:nodoc:
        collection.send(method, *args, &block)
      end

    end
  end
end
