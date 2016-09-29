# -*- coding: utf-8 -*-
# fcd1, 08/30/16: Original code was copied verbatim from
# hypatia-new, with the exception of some hard-coded constants
# that were moved to a config file.

require 'net/http'
require 'hyacinth/ezid/server_response'
require 'hyacinth/ezid/doi'

module Hyacinth::Ezid
  class ApiSession
    attr_accessor :naa, :username, :password
    attr_reader :scheme, :last_response_from_server

    # fcd1, 08/31/16: Could not find any use of the following two constants in the
    # hypatia-new codebase.
    VERSION = '0.2.1'
    APIVERSION = 'EZID API, Version 2'

    SCHEMES = { ark: 'ark:/', doi: 'doi:' }

    IDENTIFIER_STATUS = { public: 'public',
                          reserved: 'reserved',
                          unavailable: 'unavailable' }

    def initialize(username = EZID[:test_user],
                   password = EZID[:test_password])
      @username = username
      # @username = 'foo'
      @password = password
      # @password = 'bar'
      @last_response_from_server = nil
    end

    def get_identifier_metadata(identifier)
      # identifier = identifier.to_str
      # identifier = identifier.split(' | ')[0] if identifier.include?('| ark:/')
      request_uri = '/id/' + identifier
      response = call_api(request_uri, :get)
      @last_response_from_server = Hyacinth::Ezid::ServerResponse.new response
      # Ezid::Record.new(self, request.response['identifier'], request.response['metadata'], true)
      # Maybe the way to go is to create a record, like the old code does
      # response.body
      # response
      @last_response_from_server.parsed_body_hash
    end

    def mint_identifier(identifier_type = :doi,
                        identifier_status = Hyacinth::Ezid::Doi::IDENTIFIER_STATUS[:reserved],
                        shoulder = EZID[:test_shoulder][:doi],
                        metadata = {})
      # we only handle doi identifiers.
      return nil unless identifier_type == :doi
      @identifier_type = identifier_type
      @shoulder = shoulder
      metadata['_status'] = identifier_status
      request_uri = "/shoulder/#{@shoulder}"
      response = call_api(request_uri, :post, metadata)
      @last_response_from_server = Hyacinth::Ezid::ServerResponse.new response

      # following code chunk assumes we asked to mint a DOI identifier. Code will need to be changed
      # if ARK or URN identifiers support is added
      # BEGIN_CHUNK
      Hyacinth::Ezid::Doi.new(@last_response_from_server.doi,
                              @last_response_from_server.ark,
                              identifier_status) if @last_response_from_server.success?
      # END_CHUNK
    end

    # metada_hash will contain the metadata, including the EZID internal metadata
    # The datacite metadata (in XML format) will stored as value under the key 'datacite'
    # For the EZID internal data, the key is the name of the element as given in the EZID API.
    # For example, the key used for the identifier status is the element name '_status'
    def modify_identifier(identifier, metadata_hash)
      request_uri = '/id/' + identifier
      response = call_api(request_uri, :post, metadata_hash)
      response
    end

    def create(identifier, metadata = {})
      metadata = transform_metadata(metadata)
      request_uri = '/id/' + build_identifier(identifier)

      request = call_api(request_uri, :post, metadata)
      return request if request.errored?

      get(request)
    end

    def transform_metadata(metadata)
      metadata['_status'] = PRIVATE unless metadata['_status']
      metadata
    end

    def build_identifier(identifier)
      unless identifier.start_with?(ApiSession::SCHEMES[:ark]) ||
             identifier.start_with?(ApiSession::SCHEMES[:doi])
        identifier = @shoulder + identifier
      end
      identifier
    end

    def get(identifier)
      identifier = identifier.to_str
      identifier = identifier.split(' | ')[0] if identifier.include?('| ark:/')
      request_uri = '/id/' + identifier
      request = call_api(request_uri, :get)
      return request if request.errored?
      Ezid::Record.new(self, request.response['identifier'], request.response['metadata'], true)
    end

    def delete(identifier)
      request_uri = '/id/' + identifier
      call_api(request_uri, :delete)
    end

    # public utility methods

    # def record_modify(identifier, metadata, clear = false)
    #   if clear
    #     # TODO: clear old metadata
    #   end
    #   metadata.each do |name, value|
    #     modify(identifier, name, value)
    #   end
    #   get(identifier)
    # end

    private

      def call_api(request_uri, request_method, request_data = nil)
        uri = URI(EZID[:url] + request_uri)

        # which HTTP method to use?
        if request_method == :get
          request = Net::HTTP::Get.new uri.request_uri
        elsif request_method == :put
          request = Net::HTTP::Put.new uri.request_uri
          request.body = make_anvl(request_data)
        elsif request_method == :post
          request = Net::HTTP::Post.new uri.request_uri
          request.body = make_anvl(request_data)
          # request.body = '_status: public'
        elsif request_method == :delete
          request = Net::HTTP::Delete.new uri.request_uri
        end

        request.basic_auth @username, @password
        request.add_field('Content-Type', 'text/plain; charset=UTF-8')

        result = Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
          response = http.request(request)
          Rails.logger.info "=== EZID request result: " + response.body
          # parse_record http.request(request).body
          response
        end
        result
      end

      def parse_record(ezid_response)
        parts = ezid_response.split("\n")
        identifier = parts[0].split(': ')[1]
        metadata = {}
        if parts.length > 1
          parts[1..-1].each do |p|
            pair = p.split(': ')
            metadata[pair[0]] = pair[1]
          end
          record = { 'identifier' => identifier, 'metadata' => metadata }
        else
          record = identifier
        end
        record
      end

      def make_anvl(metadata)
        # fcd1, 08/31/16: Rubocop prefers a lambda instead of nested method definition
        # def escape(s)
        #   URI.escape(s, /[%:\n\r]/)
        #  end
        escape = -> (s) { URI.escape(s, /[%:\n\r]/) }
        anvl = ''
        metadata.each do |n, v|
          # fcd1, 08/31/16: code changes due to lambda instead of nested method defintion
          # anvl += escape(n.to_s) + ': ' + escape(v.to_s) + "\n"
          anvl += escape.call(n.to_s) + ': ' + escape.call(v.to_s) + "\n"
        end
        # remove last newline. there is probably a really good way to
        # avoid adding it in the first place. if you know it, please fix.
        # anvl.strip.encode!('UTF-8')
        anvl.strip
      end
  end
end
