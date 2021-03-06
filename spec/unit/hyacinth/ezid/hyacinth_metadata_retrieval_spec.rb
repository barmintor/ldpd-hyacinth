require 'rails_helper'

describe Hyacinth::Ezid::HyacinthMetadataRetrieval do

  let(:dod) {
    data = JSON.parse( fixture('lib/hyacinth/ezid/ezid_item.json').read )
    data['identifiers'] = ['item.' + SecureRandom.uuid] # random identifer to avoid collisions
    data
  }

  context "#new:" do
    it "get title" do
      local_metadata_retrieval = Hyacinth::Ezid::HyacinthMetadataRetrieval.new dod
      expected_full_title = 'The Catcher in the Rye'
      actual_full_title = local_metadata_retrieval.title
      expect(actual_full_title).to eq(expected_full_title)
    end
  end

  context "#abstract:" do
    it "abstract" do
      local_metadata_retrieval = Hyacinth::Ezid::HyacinthMetadataRetrieval.new dod
      expected_abstract = 'This is an abstract; yes, a very nice abstract'
      actual_abstract = local_metadata_retrieval.abstract
      expect(actual_abstract).to eq(expected_abstract)
    end
  end

  context "#type_of_resource:" do
    it "type_of_resource" do
      local_metadata_retrieval = Hyacinth::Ezid::HyacinthMetadataRetrieval.new dod
      expected_type_of_resource = 'still image'
      actual_type_of_resource = local_metadata_retrieval.type_of_resource
      expect(actual_type_of_resource).to eq(expected_type_of_resource)
    end
  end

  context "#date_issued_start_year:" do
    it "date_issued_start_year" do
      local_metadata_retrieval = Hyacinth::Ezid::HyacinthMetadataRetrieval.new dod
      expected_date = '2015'
      actual_date = local_metadata_retrieval.date_issued_start_year
      expect(actual_date).to eq(expected_date)
    end
  end

  context "#parent_publication_issn:" do
    it "parent_publication_issn" do
      local_metadata_retrieval = Hyacinth::Ezid::HyacinthMetadataRetrieval.new dod
      expected_issn = '1932-6203'
      actual_issn = local_metadata_retrieval.parent_publication_issn
      expect(actual_issn).to eq(expected_issn)
    end
  end

  context "#parent_publication_isbn:" do
    it "parent_publication_isbn" do
      local_metadata_retrieval = Hyacinth::Ezid::HyacinthMetadataRetrieval.new dod
      expected_isbn = '0670734608'
      actual_isbn = local_metadata_retrieval.parent_publication_isbn
      expect(actual_isbn).to eq(expected_isbn)
    end
  end

  context "#parent_publication_doi:" do
    it "parent_publication_doi" do
      local_metadata_retrieval = Hyacinth::Ezid::HyacinthMetadataRetrieval.new dod
      expected_doi = '10.1371/journal.pone.0119638'
      actual_doi = local_metadata_retrieval.parent_publication_doi
      expect(actual_doi).to eq(expected_doi)
    end
  end

  context "#doi_identifier" do
    it "doi_identifier" do
      local_metadata_retrieval = Hyacinth::Ezid::HyacinthMetadataRetrieval.new dod
      expected_doi_identifier = '10.1371/journal.pone.0119638'
      actual_doi_identifier = local_metadata_retrieval.doi_identifier
      expect(actual_doi_identifier).to eq(expected_doi_identifier)
    end
  end

  context "#handle_net_identifier" do
    it "handle_net_identifier" do
      local_metadata_retrieval = Hyacinth::Ezid::HyacinthMetadataRetrieval.new dod
      expected_handle_net_identifier = 'http://hdl.handle.net/10022/AC:P:29183'
      actual_handle_net_identifier = local_metadata_retrieval.handle_net_identifier
      expect(actual_handle_net_identifier).to eq(expected_handle_net_identifier)
    end
  end

  context "#subject_topic:" do
    it "subject_topic" do
      local_metadata_retrieval = Hyacinth::Ezid::HyacinthMetadataRetrieval.new dod
      expected_subjects_topic = ['Educational attainment','Parental influences','Mother and child--Psychological aspects']
      actual_subjects_topic = local_metadata_retrieval.subjects_topic
      expect(actual_subjects_topic).to eq(expected_subjects_topic)
    end
  end

  context "#date_created:" do
    it "date_created" do
      local_metadata_retrieval = Hyacinth::Ezid::HyacinthMetadataRetrieval.new dod
      expected_date_created = '2015-02-04'
      actual_date_created = local_metadata_retrieval.date_created
      expect(actual_date_created).to eq(expected_date_created)
    end
  end

  context "#date_modified:" do
    it "date_modified" do
      local_metadata_retrieval = Hyacinth::Ezid::HyacinthMetadataRetrieval.new dod
      expected_date_modified = '2016-03-31'
      actual_date_modified = local_metadata_retrieval.date_modified
      expect(actual_date_modified).to eq(expected_date_modified)
    end
  end

  context "#process_names works:" do
    it "creators set" do
      local_metadata_retrieval = Hyacinth::Ezid::HyacinthMetadataRetrieval.new dod
      expected_creators = ['Salinger, J. D.','Lincoln, Abraham']
      expect(local_metadata_retrieval.creators).to eq(expected_creators)
    end

    it "editors set" do
      local_metadata_retrieval = Hyacinth::Ezid::HyacinthMetadataRetrieval.new dod
      expected_editors = ['Lincoln, Abraham']
      expect(local_metadata_retrieval.editors).to eq(expected_editors)
    end
  end
end
