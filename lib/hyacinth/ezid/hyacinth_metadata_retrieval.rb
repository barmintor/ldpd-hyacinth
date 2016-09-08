# Following module contains functionality to retrieve metadata
# from the dynamic_field_data hash (which is an instance variable
# of DigitalObject)
module Hyacinth::Ezid
  class HyacinthMetadataRetrieval
    attr_reader :creators, :editors, :moderators, :contributors
    def initialize(dynamic_field_data_arg)
      # dfd is shorthand for dynamic_field_data
      @dfd = dynamic_field_data_arg
      @creators = []
      @editors = []
      @moderators = []
      @contributors = []
      process_names
    end

    # Following returns the title of an item. NOTE: if ever an item contains
    # multiple titles, it will only return the first one.
    def title
      # concatenates the non sort portion with the sort portion
      non_sort_portion = @dfd['title'][0]['title_non_sort_portion'] if @dfd['title'][0].key? 'title_non_sort_portion'
      sort_portion = @dfd['title'][0]['title_sort_portion']
      "#{non_sort_portion} #{sort_portion}"
    end

    # Following returns the abstract of an item. NOTE: if ever an item contains
    # multiple abstracts, it will only return the first one.
    def abstract
      @dfd['abstract'][0]['abstract_value'] if @dfd.key? 'abstract'
    end

    # Following returns the starting year of the Date Issued field.
    # Date is encoded using w3cdtf, so year is always present at start of date
    def date_issued_start_year
      @dfd['date_issued'][0]['date_issued_start_value'][0..3] if @dfd.key? 'date_issued'
    end

    def parent_publication_issn
      @dfd['parent_publication'][0]['parent_publication_issn'] if @dfd.key? 'parent_publication'
    end

    def parent_publication_isbn
      @dfd['parent_publication'][0]['parent_publication_isbn'] if @dfd.key? 'parent_publication'
    end

    def parent_publication_doi
      @dfd['parent_publication'][0]['parent_publication_doi'] if @dfd.key? 'parent_publication'
    end

    def doi_identifier
      @dfd['doi_identifier'][0]['doi_identifier_value'] if @dfd.key? 'doi_identifier'
    end

    def publisher
      @dfd['publisher'][0]['publisher_value'] if @dfd.key? 'publisher'
    end

    def process_names
      @dfd['name'].each do |name|
        name['name_role'].each do |role|
          role_value = role['name_role_term']['value'].downcase
          case role_value
          when 'author' then @creators << name['name_term']['value']
          when 'editor' then @editors << name['name_term']['value']
          when 'moderator' then @moderators << name['name_term']['value']
          when 'contributor' then @contributors << name['name_term']['value']
          end
        end
      end
    end

    def subjects_topic
      subjects_topic = []
      @dfd['subject_topic'].each do |topic|
        subjects_topic << topic['subject_topic_term']['value']
      end
      subjects_topic
    end
  end
end
