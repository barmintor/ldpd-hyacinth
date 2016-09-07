# Following module contains functionality to retrieve metadata
# from the dynamic_field_data hash (which is an instance variable
# of DigitalObject)
module Hyacinth::Ezid
  class MetadataRetrieval
    attr_reader :creators, :editors, :moderators, :contributors
    def initialize(dynamic_field_data_arg)
      # dfd is shorthand for dynamic_field_data
      @dfd = dynamic_field_data_arg
      @creators = []
      @editors = []
      @moderators = []
      @contributors = []
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

    # Following will return a string containing the authors (i.e. names with role set to author)
    # in the following format:
    # 'Smith, John; Doe, Jane'
    def build_author_string
      author_string = ''
      names = @dfd['name']
      names.each do |name|
        # puts name.inspect
        roles = name['name_role']
        # only process authors.
        author_string += name['name_term']['value'] + '; ' if author? roles
      end
      author_string[0..-3]
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

    def author?(roles)
      roles.each do |role|
        # casecmp returns 0 if strings are equal, ignore case
        return true if role['name_role_term']['value'].casecmp('author').zero?
      end
      false
    end
  end
end
