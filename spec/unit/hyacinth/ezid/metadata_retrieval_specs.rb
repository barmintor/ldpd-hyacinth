require 'rails_helper'

describe Hyacinth::Ezid::MetadataRetrieval do

  let(:sample_item_digital_object_data) {
    dod = JSON.parse( fixture('sample_digital_object_data/ezid_item.json').read )
    dod['identifiers'] = ['item.' + SecureRandom.uuid] # random identifer to avoid collisions
    dod
  }

  before(:context) do


  end

  context "#new:" do
    
    it "get title" do
      # dfd: dynamic_field_data
      dfd = sample_item_digital_object_data['dynamic_field_data']
      local_metadata_retrieval = Hyacinth::Ezid::MetadataRetrieval.new dfd
      # puts sample_item_digital_object_data
      expected_full_title = 'The Catcher in the Rye'
      actual_full_title = local_metadata_retrieval.title
      expect(actual_full_title).to eq(expected_full_title)
    end

  end

  context "#build_author_string:" do
    
    it "build string containing authors" do
      # dfd: dynamic_field_data
      dfd = sample_item_digital_object_data['dynamic_field_data']
      local_metadata_retrieval = Hyacinth::Ezid::MetadataRetrieval.new dfd
      # puts sample_item_digital_object_data
      expected_author_string = 'Salinger, J. D.; Lincoln, Abraham'
      actual_author_string = local_metadata_retrieval.build_author_string
      expect(actual_author_string).to eq(expected_author_string)
    end

  end

  context "#abstract:" do
    
    it "abstract" do
      # dfd: dynamic_field_data
      dfd = sample_item_digital_object_data['dynamic_field_data']
      local_metadata_retrieval = Hyacinth::Ezid::MetadataRetrieval.new dfd
      # puts sample_item_digital_object_data
      expected_abstract = 'This is an abstract; yes, a very nice abstract'
      actual_abstract = local_metadata_retrieval.abstract
      expect(actual_abstract).to eq(expected_abstract)
    end

  end

  context "#process_names:" do
    
    it "creators set" do
      dfd = sample_item_digital_object_data['dynamic_field_data']
      local_metadata_retrieval = Hyacinth::Ezid::MetadataRetrieval.new dfd
      expected_creators = ['Salinger, J. D.','Lincoln, Abraham']
      local_metadata_retrieval.process_names
      expect(local_metadata_retrieval.creators).to eq(expected_creators)
    end

    it "editors set" do
      dfd = sample_item_digital_object_data['dynamic_field_data']
      local_metadata_retrieval = Hyacinth::Ezid::MetadataRetrieval.new dfd
      expected_editors = ['Lincoln, Abraham']
      local_metadata_retrieval.process_names
      expect(local_metadata_retrieval.editors).to eq(expected_editors)
    end

  end

end
