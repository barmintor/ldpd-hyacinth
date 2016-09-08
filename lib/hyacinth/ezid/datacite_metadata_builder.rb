# Following module contains functionality to create the XML
# containing the metadata, using the datacite metadata scheme
module Hyacinth::Ezid
  class DataciteMetadataBuilder
    def initialize(hyacinth_metadata_retrieval_arg)
      # dfd is shorthand for dynamic_field_data
      @hyacinth_metadata = hyacinth_metadata_retrieval_arg
    end

    def datacite_xml
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.resource('xmlns' => 'http://datacite.org/schema/kernel-3',
                     'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
                     'xsi:schemaLocation' => 'http://datacite.org/schema/kernel-3 http://schema.datacite.org/meta/kernel-3/metadata.xsd') do
          xml.identifier('identifierType' => 'DOI') { xml.text @hyacinth_metadata.doi_identifier }

          xml.titles { xml.title @hyacinth_metadata.title } if @hyacinth_metadata.title
          xml.publisher EZID[:ezid_publisher]
          xml.publicationYear @hyacinth_metadata.date_issued_start_year
          add_creators xml
          add_subjects xml
          add_contributors xml
          # addDates(xml)
          # xml.resourceType('resourceTypeGeneral' => Ezid::Helper.mapToResourceType(@valuesMap[@@TYPE_OF_RESOURCE]))
          # addDescriptions(xml)
          # addRelatedIdentifiers(xml)
        end
      end
      builder.to_xml
    end

    def add_subjects(xml)
      xml.subjects do
        @hyacinth_metadata.subjects_topic.each { |topic| xml.subject topic }
      end unless @hyacinth_metadata.subjects_topic.empty?
    end

    def add_creators(xml)
      xml.creators do
        @hyacinth_metadata.creators.each do |name|
          xml.creator { xml.creatorName name }
        end
      end
    end

    def add_contributors(xml)
      xml.contributors do
        @hyacinth_metadata.editors.each do |name|
          xml.contributor('contributorType' => 'Editor') { xml.contributorName name }
        end
        @hyacinth_metadata.moderators.each do |name|
          xml.contributor('contributorType' => 'Other') { xml.contributorName name }
        end
        @hyacinth_metadata.contributors.each do |name|
          xml.contributor('contributorType' => 'Other') { xml.contributorName name }
        end
      end
    end
  end
end
