require 'rails_helper'
require 'equivalent-xml'

describe Hyacinth::Ezid::DataciteMetadataBuilder do

  let(:sample_item_digital_object_data) {
    dod = JSON.parse( fixture('sample_digital_object_data/ezid_item.json').read )
    dod['identifiers'] = ['item.' + SecureRandom.uuid] # random identifer to avoid collisions
    dod
  }

  before(:context) do

    @expected_xml = Nokogiri::XML(fixture('lib/hyacinth/ezid/datacite.xml').read)

  end

  context "#datacite_xml:" do
    
    it "datacite_xml" do
      dfd = sample_item_digital_object_data['dynamic_field_data']
      metadata_retrieval = Hyacinth::Ezid::HyacinthMetadataRetrieval.new dfd
      metadata_builder = Hyacinth::Ezid::DataciteMetadataBuilder.new metadata_retrieval
      actual_xml = metadata_builder.datacite_xml
      expect(EquivalentXml.equivalent?(@expected_xml, actual_xml)).to eq(true)
      
    end

  end

end
