require 'rails_helper'

describe Hyacinth::Ezid::HyacinthMetadataRetrieval do

  let(:sample_item_digital_object_data) {
    dod = JSON.parse( fixture('sample_digital_object_data/ezid_item.json').read )
    dod['identifiers'] = ['item.' + SecureRandom.uuid] # random identifer to avoid collisions
    dod
  }

  before(:context) do


  end

  context "#new:" do
    
    it "get title" do
      dfd = sample_item_digital_object_data['dynamic_field_data']
      local_metadata_retrieval = Hyacinth::Ezid::HyacinthMetadataRetrieval.new dfd
      expected_full_title = 'The Catcher in the Rye'
      actual_full_title = local_metadata_retrieval.title
      expect(actual_full_title).to eq(expected_full_title)
    end

  end

  context "#abstract:" do
    
    it "abstract" do
      dfd = sample_item_digital_object_data['dynamic_field_data']
      local_metadata_retrieval = Hyacinth::Ezid::HyacinthMetadataRetrieval.new dfd
      expected_abstract = 'This is an abstract; yes, a very nice abstract'
      actual_abstract = local_metadata_retrieval.abstract
      expect(actual_abstract).to eq(expected_abstract)
    end

  end

  context "#date_issued_start_year:" do
    
    it "date_issued_start_year" do
      dfd = sample_item_digital_object_data['dynamic_field_data']
      local_metadata_retrieval = Hyacinth::Ezid::HyacinthMetadataRetrieval.new dfd
      expected_date = '2015'
      actual_date = local_metadata_retrieval.date_issued_start_year
      expect(actual_date).to eq(expected_date)
    end

  end

  context "#parent_publication_issn:" do
    
    it "parent_publication_issn" do
      dfd = sample_item_digital_object_data['dynamic_field_data']
      local_metadata_retrieval = Hyacinth::Ezid::HyacinthMetadataRetrieval.new dfd
      expected_issn = '1932-6203'
      actual_issn = local_metadata_retrieval.parent_publication_issn
      expect(actual_issn).to eq(expected_issn)
    end

  end

  context "#parent_publication_isbn:" do
    
    it "parent_publication_isbn" do
      dfd = sample_item_digital_object_data['dynamic_field_data']
      local_metadata_retrieval = Hyacinth::Ezid::HyacinthMetadataRetrieval.new dfd
      expected_isbn = '0670734608'
      actual_isbn = local_metadata_retrieval.parent_publication_isbn
      expect(actual_isbn).to eq(expected_isbn)
    end

  end

  context "#parent_publication_doi:" do
    
    it "parent_publication_doi" do
      dfd = sample_item_digital_object_data['dynamic_field_data']
      local_metadata_retrieval = Hyacinth::Ezid::HyacinthMetadataRetrieval.new dfd
      expected_doi = '10.1371/journal.pone.0119638'
      actual_doi = local_metadata_retrieval.parent_publication_doi
      expect(actual_doi).to eq(expected_doi)
    end

  end

  context "#subject_topic:" do
    
    it "subject_topic" do
      dfd = sample_item_digital_object_data['dynamic_field_data']
      local_metadata_retrieval = Hyacinth::Ezid::HyacinthMetadataRetrieval.new dfd
      expected_subjects_topic = ['Educational attainment','Parental influences','Mother and child--Psychological aspects']
      actual_subjects_topic = local_metadata_retrieval.subjects_topic
      expect(actual_subjects_topic).to eq(expected_subjects_topic)
    end

  end

  context "#process_names:" do
    
    it "creators set" do
      dfd = sample_item_digital_object_data['dynamic_field_data']
      local_metadata_retrieval = Hyacinth::Ezid::HyacinthMetadataRetrieval.new dfd
      expected_creators = ['Salinger, J. D.','Lincoln, Abraham']
      local_metadata_retrieval.process_names
      expect(local_metadata_retrieval.creators).to eq(expected_creators)
    end

    it "editors set" do
      dfd = sample_item_digital_object_data['dynamic_field_data']
      local_metadata_retrieval = Hyacinth::Ezid::HyacinthMetadataRetrieval.new dfd
      expected_editors = ['Lincoln, Abraham']
      local_metadata_retrieval.process_names
      expect(local_metadata_retrieval.editors).to eq(expected_editors)
    end

  end

end
