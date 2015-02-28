namespace :hyacinth do
  namespace :projects do

    # Durst namespace for Durst project tasks
    namespace :durst do

      task :setup => :environment do

        # Load certain records that we'll be referencing

        cul_pid_generator = PidGenerator.find_by(namespace: 'cul')

        dot_item = DigitalObjectType.find_by(string_key: 'item')
        dot_group = DigitalObjectType.find_by(string_key: 'group')
        dot_asset = DigitalObjectType.find_by(string_key: 'asset')

        desc_metadata_xml_ds = XmlDatastream.find_by(string_key: 'descMetadata')

        dfc_identifiers = DynamicFieldGroupCategory.find_by(display_label: 'Identifiers')
        dfc_descriptive_metadata = DynamicFieldGroupCategory.find_by(display_label: 'Descriptive Metadata')
        dfc_physical_information = DynamicFieldGroupCategory.find_by(display_label: 'Physical Information')
        dfc_location_and_holdings = DynamicFieldGroupCategory.find_by(display_label: 'Location and Holdings')
        dfc_subject_data = DynamicFieldGroupCategory.find_by(display_label: 'Subject Data')
        dfc_geographic_data = DynamicFieldGroupCategory.find_by(display_label: 'Geographic Data')
        dfc_notes = DynamicFieldGroupCategory.find_by(display_label: 'Notes')
        dfc_digitization = DynamicFieldGroupCategory.find_by(display_label: 'Digitization')
        dfc_contextual_data = DynamicFieldGroupCategory.find_by(display_label: 'Contextual Data')
        dfc_record_info = DynamicFieldGroupCategory.find_by(display_label: 'Record Information')
        dfc_other = DynamicFieldGroupCategory.find_by(display_label: 'Other')
        dfc_asset_data = DynamicFieldGroupCategory.find_by(display_label: 'Asset Data')




        # Create Durst project
        durst_project = Project.create!(string_key: 'durst', display_label: 'Seymour B. Durst Old York Library', pid_generator: cul_pid_generator)

        possible_durst_user_file = File.join(Rails.root, '/config/durst_user_accounts.yml')
        if File.exists?(possible_durst_user_file)
          YAML.load_file(possible_durst_user_file).each {|service_user_entry, service_user_info|
            User.create!(
              :email => service_user_info['email'],
              :password => service_user_info['password'],
              :password_confirmation => service_user_info['password'],
              :first_name => service_user_info['first_name'],
              :last_name => service_user_info['last_name'],
              :is_admin => service_user_info['is_admin']
            )
          }
        end

        # Create AuthorizedTerms and add them to the correct ControlledVocabularies
        AuthorizedTerm.create!(
          value: 'Avery Architectural & Fine Arts Library, Columbia University',
          code: 'NNC-A',
          authority: 'marcorg',
          controlled_vocabulary: ControlledVocabulary.find_by(string_key: 'physical_location')
        )
        AuthorizedTerm.create!(
          value: 'Seymour B. Durst Old York Library Collection',
          controlled_vocabulary: ControlledVocabulary.find_by(string_key: 'collection')
        )

        # Create required dynamic fields that don't currently exist

        marc_005_last_modified = DynamicFieldGroup.create!(string_key: 'marc_005_last_modified', display_label: 'Marc 005 Last Modified', xml_datastream: nil, dynamic_field_group_category: dfc_other, is_repeatable: false,
          dynamic_fields: [DynamicField.new(string_key: 'marc_005_last_modified_value', display_label: 'Value', dynamic_field_type: DynamicField::Type::STRING, is_single_field_searchable: true, standalone_field_label: 'Marc 005 Last Modified')]
        )

        alternative_title = DynamicFieldGroup.create!(string_key: 'alternative_title', display_label: 'Alternative Title', xml_datastream: desc_metadata_xml_ds, dynamic_field_group_category: dfc_descriptive_metadata, is_repeatable: true,
          dynamic_fields: [
            DynamicField.new(string_key: 'alternative_title_non_sort_portion', display_label: 'Non-Sort Portion', dynamic_field_type: DynamicField::Type::STRING),
            DynamicField.new(string_key: 'alternative_title_sort_portion', display_label: 'Sort Portion', dynamic_field_type: DynamicField::Type::STRING, is_keyword_searchable: true, is_searchable_title_field: true)
          ]
        )

        abstract = DynamicFieldGroup.create!(string_key: 'abstract', display_label: 'Abstract', xml_datastream: desc_metadata_xml_ds, dynamic_field_group_category: dfc_descriptive_metadata, is_repeatable: false,
          dynamic_fields: [DynamicField.new(string_key: 'abstract_value', display_label: 'Value', dynamic_field_type: DynamicField::Type::TEXTAREA, is_keyword_searchable: true)]
        )

        name = DynamicFieldGroup.create!(string_key: 'name', display_label: 'Name', xml_datastream: desc_metadata_xml_ds, dynamic_field_group_category: dfc_descriptive_metadata, is_repeatable: true,
          dynamic_fields: [
            DynamicField.new(string_key: 'name_type', display_label: 'Type', dynamic_field_type: DynamicField::Type::SELECT, additional_data_json: {
              select_options: [
                {value: '', display_label: '- Select an Option -'},
                {value: 'personal', display_label: 'Personal'},
                {value: 'corporate', display_label: 'Corporate'},
                {value: 'conference', display_label: 'Event'}
              ]
            }.to_json),
            DynamicField.new(string_key: 'name_value', display_label: 'Value', dynamic_field_type: DynamicField::Type::STRING, is_facet_field: true, is_keyword_searchable: true, is_single_field_searchable: true, standalone_field_label: 'Name'),
            DynamicField.new(string_key: 'name_value_uri', display_label: 'Value URI', dynamic_field_type: DynamicField::Type::AUTHORIZED_TERM_VALUE_URI, is_single_field_searchable: true, standalone_field_label: 'Name Value URI'),
            DynamicField.new(string_key: 'name_authority', display_label: 'Authority', dynamic_field_type: DynamicField::Type::AUTHORIZED_TERM_AUTHORITY),
            DynamicField.new(string_key: 'name_authority_uri', display_label: 'Authority URI', dynamic_field_type: DynamicField::Type::AUTHORIZED_TERM_AUTHORITY_URI),
          ]
        )
          # --> Start Child DynamicFieldGroups
            DynamicFieldGroup.create!(string_key: 'name_role', display_label: 'Role', is_repeatable: true, parent_dynamic_field_group: name, dynamic_fields: [
              DynamicField.new(string_key: 'name_role_value', display_label: 'Value', dynamic_field_type: DynamicField::Type::STRING),
              DynamicField.new(string_key: 'name_role_type', display_label: 'Type', dynamic_field_type: DynamicField::Type::SELECT, additional_data_json: {
                select_options: [
                  {value: '', display_label: '- Select an Option -'},
                  {value: 'text', display_label: 'text'},
                  {value: 'code', display_label: 'code'}
                ]
              }.to_json)
            ])
          # --> End Child DynamicFieldGroups

        publisher = DynamicFieldGroup.create!(string_key: 'publisher', display_label: 'Publisher', xml_datastream: desc_metadata_xml_ds, dynamic_field_group_category: dfc_descriptive_metadata, is_repeatable: true,
          dynamic_fields: [DynamicField.new(string_key: 'publisher_value', display_label: 'Value', dynamic_field_type: DynamicField::Type::STRING, is_keyword_searchable: true, is_single_field_searchable: true, standalone_field_label: 'Publisher')]
        )

        place_of_origin = DynamicFieldGroup.create!(string_key: 'place_of_origin', display_label: 'Place of Origin', xml_datastream: desc_metadata_xml_ds, dynamic_field_group_category: dfc_descriptive_metadata, is_repeatable: true,
          dynamic_fields: [DynamicField.new(string_key: 'place_of_origin_value', display_label: 'Value', dynamic_field_type: DynamicField::Type::STRING, is_keyword_searchable: true, is_single_field_searchable: true, standalone_field_label: 'Place of Origin')]
        )

        date_created = DynamicFieldGroup.create!(string_key: 'date_created', display_label: 'Date Created', xml_datastream: desc_metadata_xml_ds, dynamic_field_group_category: dfc_descriptive_metadata, is_repeatable: true,
          dynamic_fields: [
            DynamicField.new(string_key: 'date_created_start_value', display_label: 'Single or Start Date', dynamic_field_type: DynamicField::Type::DATE, is_single_field_searchable: true, standalone_field_label: 'Date Created - Start or Single Date'),
            DynamicField.new(string_key: 'date_created_end_value', display_label: 'End Date', dynamic_field_type: DynamicField::Type::DATE, is_single_field_searchable: true, standalone_field_label: 'Date Created - End Date'),
            DynamicField.new(string_key: 'date_created_type', display_label: 'Type', dynamic_field_type: DynamicField::Type::SELECT, additional_data_json: {
              select_options: [
                {value: '', display_label: '- Not Specified -'},
                {value: 'approximate', display_label: 'Approximate'},
                {value: 'inferred', display_label: 'Inferred'},
                {value: 'questionable', display_label: 'Questionable'}
              ]
            }.to_json),
            DynamicField.new(string_key: 'date_created_key_date', display_label: 'Key Date?', dynamic_field_type: DynamicField::Type::BOOLEAN)
          ]
        )

        date_created_textual = DynamicFieldGroup.create!(string_key: 'date_created_textual', display_label: 'Date Created Textual', xml_datastream: desc_metadata_xml_ds, dynamic_field_group_category: dfc_descriptive_metadata, is_repeatable: false,
          dynamic_fields: [DynamicField.new(string_key: 'date_created_textual_value', display_label: 'Value', dynamic_field_type: DynamicField::Type::STRING, is_keyword_searchable: true, is_single_field_searchable: true, standalone_field_label: 'Date Created - Textual')]
        )

        date_other = DynamicFieldGroup.create!(string_key: 'date_other', display_label: 'Date Other', xml_datastream: desc_metadata_xml_ds, dynamic_field_group_category: dfc_descriptive_metadata, is_repeatable: true,
          dynamic_fields: [
            DynamicField.new(string_key: 'date_other_start_value', display_label: 'Single or Start Date', dynamic_field_type: DynamicField::Type::DATE, is_single_field_searchable: true, standalone_field_label: 'Date Other - Start or Single Date'),
            DynamicField.new(string_key: 'date_other_end_value', display_label: 'End Date', dynamic_field_type: DynamicField::Type::DATE, is_single_field_searchable: true, standalone_field_label: 'Date Other - End Date'),
            DynamicField.new(string_key: 'date_other_type', display_label: 'Type', dynamic_field_type: DynamicField::Type::SELECT, additional_data_json: {
              select_options: [
                {value: '', display_label: '- Not Specified -'},
                {value: 'approximate', display_label: 'Approximate'},
                {value: 'inferred', display_label: 'Inferred'},
                {value: 'questionable', display_label: 'Questionable'}
              ]
            }.to_json),
            DynamicField.new(string_key: 'date_other_key_date', display_label: 'Key Date?', dynamic_field_type: DynamicField::Type::BOOLEAN)
          ]
        )

        date_other_textual = DynamicFieldGroup.create!(string_key: 'date_other_textual', display_label: 'Date Other Textual', xml_datastream: desc_metadata_xml_ds, dynamic_field_group_category: dfc_descriptive_metadata, is_repeatable: false,
          dynamic_fields: [DynamicField.new(string_key: 'date_other_textual_value', display_label: 'Value', dynamic_field_type: DynamicField::Type::STRING, is_keyword_searchable: true, is_single_field_searchable: true, standalone_field_label: 'Date Other - Textual')]
        )

        date_issued = DynamicFieldGroup.create!(string_key: 'date_issued', display_label: 'Date Issued', xml_datastream: desc_metadata_xml_ds, dynamic_field_group_category: dfc_descriptive_metadata, is_repeatable: true,
          dynamic_fields: [
            DynamicField.new(string_key: 'date_issued_start_value', display_label: 'Single or Start Date', dynamic_field_type: DynamicField::Type::DATE, is_single_field_searchable: true, standalone_field_label: 'Date Issued - Start or Single Date'),
            DynamicField.new(string_key: 'date_issued_end_value', display_label: 'End Date', dynamic_field_type: DynamicField::Type::DATE, is_single_field_searchable: true, standalone_field_label: 'Date Issued - End Date'),
            DynamicField.new(string_key: 'date_issued_type', display_label: 'Type', dynamic_field_type: DynamicField::Type::SELECT, additional_data_json: {
              select_options: [
                {value: '', display_label: '- Not Specified -'},
                {value: 'approximate', display_label: 'Approximate'},
                {value: 'inferred', display_label: 'Inferred'},
                {value: 'questionable', display_label: 'Questionable'}
              ]
            }.to_json),
            DynamicField.new(string_key: 'date_issued_key_date', display_label: 'Key Date?', dynamic_field_type: DynamicField::Type::BOOLEAN)
          ]
        )

        date_issued_textual = DynamicFieldGroup.create!(string_key: 'date_issued_textual', display_label: 'Date Issued Textual', xml_datastream: desc_metadata_xml_ds, dynamic_field_group_category: dfc_descriptive_metadata, is_repeatable: false,
          dynamic_fields: [DynamicField.new(string_key: 'date_issued_textual_value', display_label: 'Value', dynamic_field_type: DynamicField::Type::STRING, is_keyword_searchable: true, is_single_field_searchable: true, standalone_field_label: 'Date Issued - Textual')]
        )

        edition = DynamicFieldGroup.create!(string_key: 'edition', display_label: 'Edition', xml_datastream: desc_metadata_xml_ds, dynamic_field_group_category: dfc_descriptive_metadata, is_repeatable: false,
          dynamic_fields: [DynamicField.new(string_key: 'edition_value', display_label: 'Value', dynamic_field_type: DynamicField::Type::STRING, is_keyword_searchable: true, is_single_field_searchable: true, standalone_field_label: 'Edition')]
        )

        table_of_contents = DynamicFieldGroup.create!(string_key: 'table_of_contents', display_label: 'Table of Contents', xml_datastream: desc_metadata_xml_ds, dynamic_field_group_category: dfc_descriptive_metadata, is_repeatable: false,
          dynamic_fields: [DynamicField.new(string_key: 'table_of_contents_value', display_label: 'Value', dynamic_field_type: DynamicField::Type::TEXTAREA, is_keyword_searchable: true)]
        )

        subject_topic = DynamicFieldGroup.create!(string_key: 'subject_topic', display_label: 'Subject Topic', xml_datastream: desc_metadata_xml_ds, dynamic_field_group_category: dfc_subject_data, is_repeatable: true,
          dynamic_fields: [
            DynamicField.new(string_key: 'subject_topic_value', display_label: 'Value', dynamic_field_type: DynamicField::Type::STRING, is_facet_field: true, is_keyword_searchable: true, is_single_field_searchable: true, standalone_field_label: 'Subject Topic'),
            DynamicField.new(string_key: 'subject_topic_value_uri', display_label: 'Value URI', dynamic_field_type: DynamicField::Type::AUTHORIZED_TERM_VALUE_URI, is_single_field_searchable: true, standalone_field_label: 'Subject Topic Value URI'),
            DynamicField.new(string_key: 'subject_topic_authority', display_label: 'Authority', dynamic_field_type: DynamicField::Type::AUTHORIZED_TERM_AUTHORITY),
            DynamicField.new(string_key: 'subject_topic_authority_uri', display_label: 'Authority URI', dynamic_field_type: DynamicField::Type::AUTHORIZED_TERM_AUTHORITY_URI)
          ]
        )

        subject_durst = DynamicFieldGroup.create!(string_key: 'subject_durst', display_label: 'Subject Durst', xml_datastream: desc_metadata_xml_ds, dynamic_field_group_category: dfc_subject_data, is_repeatable: true,
          dynamic_fields: [
            DynamicField.new(string_key: 'subject_durst_value', display_label: 'Value', dynamic_field_type: DynamicField::Type::STRING, is_facet_field: true, is_keyword_searchable: true, is_single_field_searchable: true, standalone_field_label: 'Subject Durst'),
            DynamicField.new(string_key: 'subject_durst_code', display_label: 'Code', dynamic_field_type: DynamicField::Type::STRING, is_keyword_searchable: true, is_single_field_searchable: true, standalone_field_label: 'Subject Durst Code')
          ]
        )

        subject_temporal = DynamicFieldGroup.create!(string_key: 'subject_temporal', display_label: 'Subject Temporal', xml_datastream: desc_metadata_xml_ds, dynamic_field_group_category: dfc_subject_data, is_repeatable: true,
          dynamic_fields: [
            DynamicField.new(string_key: 'subject_temporal_value', display_label: 'Value', dynamic_field_type: DynamicField::Type::STRING, is_facet_field: true, is_keyword_searchable: true, is_single_field_searchable: true, standalone_field_label: 'Subject Temporal'),
            DynamicField.new(string_key: 'subject_temporal_value_uri', display_label: 'Value URI', dynamic_field_type: DynamicField::Type::AUTHORIZED_TERM_VALUE_URI, is_single_field_searchable: true, standalone_field_label: 'Subject Temporal Value URI'),
            DynamicField.new(string_key: 'subject_temporal_authority', display_label: 'Authority', dynamic_field_type: DynamicField::Type::AUTHORIZED_TERM_AUTHORITY),
            DynamicField.new(string_key: 'subject_temporal_authority_uri', display_label: 'Authority URI', dynamic_field_type: DynamicField::Type::AUTHORIZED_TERM_AUTHORITY_URI)
          ]
        )

        subject_name = DynamicFieldGroup.create!(string_key: 'subject_name', display_label: 'Subject Name', xml_datastream: desc_metadata_xml_ds, dynamic_field_group_category: dfc_subject_data, is_repeatable: true,
          dynamic_fields: [
            DynamicField.new(string_key: 'subject_name_value', display_label: 'Value', dynamic_field_type: DynamicField::Type::STRING, is_facet_field: true, is_keyword_searchable: true, is_single_field_searchable: true, standalone_field_label: 'Subject Name'),
            DynamicField.new(string_key: 'subject_name_value_uri', display_label: 'Value URI', dynamic_field_type: DynamicField::Type::AUTHORIZED_TERM_VALUE_URI, is_single_field_searchable: true, standalone_field_label: 'Subject Name Value URI'),
            DynamicField.new(string_key: 'subject_name_authority', display_label: 'Authority', dynamic_field_type: DynamicField::Type::AUTHORIZED_TERM_AUTHORITY),
            DynamicField.new(string_key: 'subject_name_authority_uri', display_label: 'Authority URI', dynamic_field_type: DynamicField::Type::AUTHORIZED_TERM_AUTHORITY_URI)
          ]
        )

        subject_title = DynamicFieldGroup.create!(string_key: 'subject_title', display_label: 'Subject Title', xml_datastream: desc_metadata_xml_ds, dynamic_field_group_category: dfc_subject_data, is_repeatable: true,
          dynamic_fields: [
            DynamicField.new(string_key: 'subject_title_value', display_label: 'Value', dynamic_field_type: DynamicField::Type::STRING, is_facet_field: true, is_keyword_searchable: true, is_single_field_searchable: true, standalone_field_label: 'Subject Title'),
            DynamicField.new(string_key: 'subject_title_value_uri', display_label: 'Value URI', dynamic_field_type: DynamicField::Type::AUTHORIZED_TERM_VALUE_URI, is_single_field_searchable: true, standalone_field_label: 'Subject Title Value URI'),
            DynamicField.new(string_key: 'subject_title_authority', display_label: 'Authority', dynamic_field_type: DynamicField::Type::AUTHORIZED_TERM_AUTHORITY),
            DynamicField.new(string_key: 'subject_title_authority_uri', display_label: 'Authority URI', dynamic_field_type: DynamicField::Type::AUTHORIZED_TERM_AUTHORITY_URI)
          ]
        )

        subject_geographic = DynamicFieldGroup.create!(string_key: 'subject_geographic', display_label: 'Subject Place', xml_datastream: desc_metadata_xml_ds, dynamic_field_group_category: dfc_geographic_data, is_repeatable: true,
          dynamic_fields: [
            DynamicField.new(string_key: 'subject_geographic_value', display_label: 'Value', dynamic_field_type: DynamicField::Type::STRING, is_facet_field: true, is_keyword_searchable: true, is_single_field_searchable: true, standalone_field_label: 'Subject Geographic'),
            DynamicField.new(string_key: 'subject_geographic_value_uri', display_label: 'Value URI', dynamic_field_type: DynamicField::Type::AUTHORIZED_TERM_VALUE_URI, is_single_field_searchable: true, standalone_field_label: 'Subject Geographic Value URI'),
            DynamicField.new(string_key: 'subject_geographic_authority', display_label: 'Authority', dynamic_field_type: DynamicField::Type::AUTHORIZED_TERM_AUTHORITY),
            DynamicField.new(string_key: 'subject_geographic_authority_uri', display_label: 'Authority URI', dynamic_field_type: DynamicField::Type::AUTHORIZED_TERM_AUTHORITY_URI)
          ]
        )

        subject_hierarchical_geographic = DynamicFieldGroup.create!(string_key: 'subject_hierarchical_geographic', display_label: 'Subject Hierarchical Geographic', xml_datastream: desc_metadata_xml_ds, dynamic_field_group_category: dfc_geographic_data, is_repeatable: true)
          # --> Start Child DynamicFieldGroups
            DynamicFieldGroup.create!(string_key: 'subject_hierarchical_geographic_country', display_label: 'Country', parent_dynamic_field_group: subject_hierarchical_geographic, is_repeatable: false,
              dynamic_fields: [
                DynamicField.new(string_key: 'subject_hierarchical_geographic_country_value', display_label: 'Value', dynamic_field_type: DynamicField::Type::STRING, is_keyword_searchable: true)
              ]
            )
            DynamicFieldGroup.create!(string_key: 'subject_hierarchical_geographic_province', display_label: 'Province', parent_dynamic_field_group: subject_hierarchical_geographic, is_repeatable: false,
              dynamic_fields: [
                DynamicField.new(string_key: 'subject_hierarchical_geographic_province_value', display_label: 'Value', dynamic_field_type: DynamicField::Type::STRING, is_keyword_searchable: true)
              ]
            )
            DynamicFieldGroup.create!(string_key: 'subject_hierarchical_geographic_region', display_label: 'Region', parent_dynamic_field_group: subject_hierarchical_geographic, is_repeatable: false,
              dynamic_fields: [
                DynamicField.new(string_key: 'subject_hierarchical_geographic_region_value', display_label: 'Value', dynamic_field_type: DynamicField::Type::STRING, is_keyword_searchable: true)
              ]
            )
            DynamicFieldGroup.create!(string_key: 'subject_hierarchical_geographic_state', display_label: 'State', parent_dynamic_field_group: subject_hierarchical_geographic, is_repeatable: false,
              dynamic_fields: [
                DynamicField.new(string_key: 'subject_hierarchical_geographic_state_value', display_label: 'Value', dynamic_field_type: DynamicField::Type::STRING, is_keyword_searchable: true)
              ]
            )
            DynamicFieldGroup.create!(string_key: 'subject_hierarchical_geographic_county', display_label: 'County', parent_dynamic_field_group: subject_hierarchical_geographic, is_repeatable: false,
              dynamic_fields: [
                DynamicField.new(string_key: 'subject_hierarchical_geographic_county_value', display_label: 'Value', dynamic_field_type: DynamicField::Type::STRING, is_keyword_searchable: true)
              ]
            )
            DynamicFieldGroup.create!(string_key: 'subject_hierarchical_geographic_borough', display_label: 'Borough', parent_dynamic_field_group: subject_hierarchical_geographic, is_repeatable: false,
              dynamic_fields: [
                DynamicField.new(string_key: 'subject_hierarchical_geographic_borough_value', display_label: 'Value', dynamic_field_type: DynamicField::Type::STRING, is_keyword_searchable: true)
              ]
            )
            DynamicFieldGroup.create!(string_key: 'subject_hierarchical_geographic_city', display_label: 'City', parent_dynamic_field_group: subject_hierarchical_geographic, is_repeatable: false,
              dynamic_fields: [
                DynamicField.new(string_key: 'subject_hierarchical_geographic_city_value', display_label: 'Value', dynamic_field_type: DynamicField::Type::STRING, is_keyword_searchable: true)
              ]
            )
            DynamicFieldGroup.create!(string_key: 'subject_hierarchical_geographic_city_section', display_label: 'City Section', parent_dynamic_field_group: subject_hierarchical_geographic, is_repeatable: true,
              dynamic_fields: [
                DynamicField.new(string_key: 'subject_hierarchical_geographic_city_section_value', display_label: 'Value', dynamic_field_type: DynamicField::Type::STRING, is_keyword_searchable: true)
              ]
            )
            DynamicFieldGroup.create!(string_key: 'subject_hierarchical_geographic_zip_code', display_label: 'ZIP Code', parent_dynamic_field_group: subject_hierarchical_geographic, is_repeatable: true,
              dynamic_fields: [
                DynamicField.new(string_key: 'subject_hierarchical_geographic_zip_code_value', display_label: 'Value', dynamic_field_type: DynamicField::Type::STRING, is_keyword_searchable: true)
              ]
            )
            DynamicFieldGroup.create!(string_key: 'subject_hierarchical_geographic_street', display_label: 'Street', parent_dynamic_field_group: subject_hierarchical_geographic, is_repeatable: true,
              dynamic_fields: [
                DynamicField.new(string_key: 'subject_hierarchical_geographic_street_value', display_label: 'Value', dynamic_field_type: DynamicField::Type::STRING, is_keyword_searchable: true)
              ]
            )
          # --> End Child DynamicFieldGroups

        coordinates = DynamicFieldGroup.create!(string_key: 'coordinates', display_label: 'Coordinates', is_repeatable: true, xml_datastream: desc_metadata_xml_ds, dynamic_field_group_category: dfc_geographic_data,
          dynamic_fields: [
            DynamicField.new(string_key: 'coordinates_value', display_label: 'Value', dynamic_field_type: DynamicField::Type::STRING, is_single_field_searchable: true, standalone_field_label: 'Coordinates')
          ]
        )

        scale = DynamicFieldGroup.create!(string_key: 'scale', display_label: 'Scale', is_repeatable: true, xml_datastream: desc_metadata_xml_ds, dynamic_field_group_category: dfc_physical_information,
          dynamic_fields: [
            DynamicField.new(string_key: 'scale_value', display_label: 'Value', dynamic_field_type: DynamicField::Type::STRING, is_keyword_searchable: true)
          ]
        )

        genre = DynamicFieldGroup.create!(string_key: 'genre', display_label: 'Genre', is_repeatable: true, xml_datastream: desc_metadata_xml_ds, dynamic_field_group_category: dfc_descriptive_metadata,
          dynamic_fields: [
            DynamicField.new(string_key: 'genre_value', display_label: 'Value', dynamic_field_type: DynamicField::Type::STRING, is_keyword_searchable: true, is_single_field_searchable: true, is_searchable_identifier_field: true, standalone_field_label: 'Genre')
          ]
        )

        view_direction = DynamicFieldGroup.create!(string_key: 'view_direction', display_label: 'View Direction', is_repeatable: false, xml_datastream: desc_metadata_xml_ds, dynamic_field_group_category: dfc_notes,
          dynamic_fields: [
            DynamicField.new(string_key: 'view_direction_value', display_label: 'Value', dynamic_field_type: DynamicField::Type::STRING, is_keyword_searchable: true)
          ]
        )

        note = DynamicFieldGroup.create!(string_key: 'note', display_label: 'Note', is_repeatable: true, xml_datastream: desc_metadata_xml_ds, dynamic_field_group_category: dfc_notes,
          dynamic_fields: [
            DynamicField.new(string_key: 'note_value', display_label: 'Value', dynamic_field_type: DynamicField::Type::TEXTAREA, is_keyword_searchable: true),
            DynamicField.new(string_key: 'note_type', display_label: 'Type', dynamic_field_type: DynamicField::Type::STRING)
          ]
        )

        extent = DynamicFieldGroup.create!(string_key: 'extent', display_label: 'Extent', is_repeatable: true, xml_datastream: desc_metadata_xml_ds, dynamic_field_group_category: dfc_physical_information,
          dynamic_fields: [
            DynamicField.new(string_key: 'extent_value', display_label: 'Value', dynamic_field_type: DynamicField::Type::STRING, is_keyword_searchable: true)
          ]
        )

        orientation = DynamicFieldGroup.create!(string_key: 'orientation', display_label: 'Orientation', is_repeatable: false, xml_datastream: desc_metadata_xml_ds, dynamic_field_group_category: dfc_notes,
          dynamic_fields: [
            DynamicField.new(string_key: 'orientation_value', display_label: 'Value', dynamic_field_type: DynamicField::Type::STRING, is_keyword_searchable: true)
          ]
        )

        series = DynamicFieldGroup.create!(string_key: 'series', display_label: 'Series', is_repeatable: true, xml_datastream: desc_metadata_xml_ds, dynamic_field_group_category: dfc_contextual_data,
          dynamic_fields: [
            DynamicField.new(string_key: 'series_title', display_label: 'Title', dynamic_field_type: DynamicField::Type::STRING, is_keyword_searchable: true)
          ]
        )

        box_title = DynamicFieldGroup.create!(string_key: 'box_title', display_label: 'Box Title', is_repeatable: false, xml_datastream: desc_metadata_xml_ds, dynamic_field_group_category: dfc_contextual_data,
          dynamic_fields: [
            DynamicField.new(string_key: 'box_title_value', display_label: 'Value', dynamic_field_type: DynamicField::Type::STRING, is_keyword_searchable: true)
          ]
        )

        group_title = DynamicFieldGroup.create!(string_key: 'group_title', display_label: 'Group Title', is_repeatable: false, xml_datastream: desc_metadata_xml_ds, dynamic_field_group_category: dfc_contextual_data,
          dynamic_fields: [
            DynamicField.new(string_key: 'group_title_value', display_label: 'Value', dynamic_field_type: DynamicField::Type::STRING, is_keyword_searchable: true)
          ]
        )

        clio_identifier = DynamicFieldGroup.create!(string_key: 'clio_identifier', display_label: 'CLIO ID', is_repeatable: true, xml_datastream: desc_metadata_xml_ds, dynamic_field_group_category: dfc_identifiers,
          dynamic_fields: [
            DynamicField.new(string_key: 'clio_identifier_value', display_label: 'Value', dynamic_field_type: DynamicField::Type::STRING, is_single_field_searchable: true, is_searchable_identifier_field: true, standalone_field_label: 'CLIO Identifier')
          ]
        )

        dims_identifier = DynamicFieldGroup.create!(string_key: 'dims_identifier', display_label: 'DIMS ID', is_repeatable: true, xml_datastream: desc_metadata_xml_ds, dynamic_field_group_category: dfc_identifiers,
          dynamic_fields: [
            DynamicField.new(string_key: 'dims_identifier_value', display_label: 'Value', dynamic_field_type: DynamicField::Type::STRING, is_single_field_searchable: true, is_searchable_identifier_field: true, standalone_field_label: 'DIMS Identifier')
          ]
        )

        durst_postcard_identifier = DynamicFieldGroup.create!(string_key: 'durst_postcard_identifier', display_label: 'Durst Postcard Identifier', is_repeatable: false, xml_datastream: desc_metadata_xml_ds, dynamic_field_group_category: dfc_identifiers,
          dynamic_fields: [
            DynamicField.new(string_key: 'durst_postcard_identifier_value', display_label: 'Value', dynamic_field_type: DynamicField::Type::STRING, is_single_field_searchable: true, is_searchable_identifier_field: true, standalone_field_label: 'Durst Postcard Identifier')
          ]
        )

        cul_assigned_postcard_identifier = DynamicFieldGroup.create!(string_key: 'cul_assigned_postcard_identifier', display_label: 'CUL-Assigned Postcard Identifier', is_repeatable: false, xml_datastream: desc_metadata_xml_ds, dynamic_field_group_category: dfc_identifiers,
          dynamic_fields: [
            DynamicField.new(string_key: 'cul_assigned_postcard_identifier_value', display_label: 'Value', dynamic_field_type: DynamicField::Type::STRING, is_single_field_searchable: true, is_searchable_identifier_field: true, standalone_field_label: 'CUL-Assigned Postcard Identifier')
          ]
        )

        filename_front_identifier = DynamicFieldGroup.create!(string_key: 'filename_front_identifier', display_label: 'Filename Front Identifier', is_repeatable: false, xml_datastream: desc_metadata_xml_ds, dynamic_field_group_category: dfc_identifiers,
          dynamic_fields: [
            DynamicField.new(string_key: 'filename_front_identifier_value', display_label: 'Value', dynamic_field_type: DynamicField::Type::STRING, is_single_field_searchable: true, is_searchable_identifier_field: true, standalone_field_label: 'Filename Front Identifier')
          ]
        )

        filename_back_identifier = DynamicFieldGroup.create!(string_key: 'filename_back_identifier', display_label: 'Filename Back Identifier', is_repeatable: false, xml_datastream: desc_metadata_xml_ds, dynamic_field_group_category: dfc_identifiers,
          dynamic_fields: [
            DynamicField.new(string_key: 'filename_back_identifier_value', display_label: 'Value', dynamic_field_type: DynamicField::Type::STRING, is_single_field_searchable: true, is_searchable_identifier_field: true, standalone_field_label: 'Filename Back Identifier')
          ]
        )

        isbn = DynamicFieldGroup.create!(string_key: 'isbn', display_label: 'ISBN', is_repeatable: false, xml_datastream: desc_metadata_xml_ds, dynamic_field_group_category: dfc_identifiers,
          dynamic_fields: [
            DynamicField.new(string_key: 'isbn_value', display_label: 'Value', dynamic_field_type: DynamicField::Type::STRING, is_single_field_searchable: true, is_searchable_identifier_field: true, standalone_field_label: 'ISBN')
          ]
        )

        issn = DynamicFieldGroup.create!(string_key: 'issn', display_label: 'ISSN', is_repeatable: false, xml_datastream: desc_metadata_xml_ds, dynamic_field_group_category: dfc_identifiers,
          dynamic_fields: [
            DynamicField.new(string_key: 'issn_value', display_label: 'Value', dynamic_field_type: DynamicField::Type::STRING, is_single_field_searchable: true, is_searchable_identifier_field: true, standalone_field_label: 'ISSN')
          ]
        )

        shelf_location = DynamicFieldGroup.create!(string_key: 'shelf_location', display_label: 'Shelf Location', is_repeatable: false, xml_datastream: desc_metadata_xml_ds, dynamic_field_group_category: dfc_location_and_holdings,
          dynamic_fields: [
            DynamicField.new(string_key: 'shelf_location_value', display_label: 'Value', dynamic_field_type: DynamicField::Type::STRING, is_keyword_searchable: true)
          ]
        )

        enumeration_and_chronology = DynamicFieldGroup.create!(string_key: 'enumeration_and_chronology', display_label: 'Enumeration and Chronology', is_repeatable: true, xml_datastream: desc_metadata_xml_ds, dynamic_field_group_category: dfc_location_and_holdings,
          dynamic_fields: [
            DynamicField.new(string_key: 'enumeration_and_chronology_value', display_label: 'Value', dynamic_field_type: DynamicField::Type::STRING, is_keyword_searchable: true)
          ]
        )

        sublocation = DynamicFieldGroup.create!(string_key: 'sublocation', display_label: 'Sublocation', is_repeatable: true, xml_datastream: desc_metadata_xml_ds, dynamic_field_group_category: dfc_location_and_holdings,
          dynamic_fields: [
            DynamicField.new(string_key: 'sublocation_value', display_label: 'Value', dynamic_field_type: DynamicField::Type::STRING, is_keyword_searchable: true)
          ]
        )

        url = DynamicFieldGroup.create!(string_key: 'url', display_label: 'URL', is_repeatable: true, xml_datastream: desc_metadata_xml_ds, dynamic_field_group_category: dfc_location_and_holdings,
          dynamic_fields: [
            DynamicField.new(string_key: 'url_value', display_label: 'Value', dynamic_field_type: DynamicField::Type::STRING, is_single_field_searchable: true, is_searchable_identifier_field: true, standalone_field_label: 'URL')
          ]
        )

        durst_favorite = DynamicFieldGroup.create!(string_key: 'durst_favorite', display_label: 'Durst Favorite', xml_datastream: nil, dynamic_field_group_category: dfc_other, is_repeatable: false,
          dynamic_fields: [
            DynamicField.new(string_key: 'durst_favorite_value', display_label: 'Value', dynamic_field_type: DynamicField::Type::BOOLEAN, is_single_field_searchable: true, standalone_field_label: 'Is Durst Favorite?')
          ]
        )

        type_of_resource = DynamicFieldGroup.create!(string_key: 'type_of_resource', display_label: 'Type of Resource', xml_datastream: desc_metadata_xml_ds, dynamic_field_group_category: dfc_other, is_repeatable: false,
          dynamic_fields: [
            DynamicField.new(string_key: 'type_of_resource_value', display_label: 'Type of Resource', dynamic_field_type: DynamicField::Type::SELECT, is_single_field_searchable: true, standalone_field_label: 'Type of Resource', additional_data_json: {
              select_options: [
                {value: '', display_label: '- Select a type -'},
                {value: 'cartographic', display_label: 'cartographic'},
                {value: 'kit', display_label: 'kit'},
                {value: 'mixed material', display_label: 'mixed material'},
                {value: 'moving image', display_label: 'moving image'},
                {value: 'notated music', display_label: 'notated'},
                {value: 'software, multimedia', display_label: 'software, multimedia'},
                {value: 'sound recording - nonmusical', display_label: 'sound recording - nonmusical'},
                {value: 'sound recording - musical', display_label: 'sound recording - musical'},
                {value: 'still image', display_label: 'still image'},
                {value: 'text', display_label: 'text'},
                {value: 'three dimensional object', display_label: 'three dimensional object'},
              ]
            }.to_json),
            DynamicField.new(string_key: 'type_of_resource_is_collection', display_label: 'Is Collection Level Record?', dynamic_field_type: DynamicField::Type::BOOLEAN, is_single_field_searchable: true, standalone_field_label: 'Is Collection Level Record?')
          ]
        )

        record_content_source = DynamicFieldGroup.create!(string_key: 'record_content_source', display_label: 'Record Content Source (Institutional Record Creator)', xml_datastream: desc_metadata_xml_ds, dynamic_field_group_category: dfc_record_info, is_repeatable: false,
          dynamic_fields: [DynamicField.new(string_key: 'record_content_source_value', display_label: 'Value', dynamic_field_type: DynamicField::Type::STRING)]
        )

        record_origin = DynamicFieldGroup.create!(string_key: 'record_origin', display_label: 'Record Origin', xml_datastream: desc_metadata_xml_ds, dynamic_field_group_category: dfc_descriptive_metadata, is_repeatable: false,
          dynamic_fields: [DynamicField.new(string_key: 'record_origin_value', display_label: 'Value', dynamic_field_type: DynamicField::Type::TEXTAREA, is_keyword_searchable: true)]
        )

        language_of_cataloging = DynamicFieldGroup.create!(string_key: 'language_of_cataloging', display_label: 'Language of Cataloging', xml_datastream: desc_metadata_xml_ds, dynamic_field_group_category: dfc_record_info, is_repeatable: false,
          dynamic_fields: [DynamicField.new(string_key: 'language_of_cataloging_value', display_label: 'Value', dynamic_field_type: DynamicField::Type::STRING)]
        )

        cul_scan_note = DynamicFieldGroup.create!(string_key: 'cul_scan_note', display_label: 'CUL Scan Note', xml_datastream: desc_metadata_xml_ds, dynamic_field_group_category: dfc_record_info, is_repeatable: false,
          dynamic_fields: [DynamicField.new(string_key: 'cul_scan_note_value', display_label: 'Value', dynamic_field_type: DynamicField::Type::STRING)]
        )



        # Enable title fields for Items, Groups and Assets
        (DynamicFieldGroup.find_by(string_key: 'title').dynamic_fields).each do |dynamic_field|
          durst_project.enabled_dynamic_fields << EnabledDynamicField.new(dynamic_field: dynamic_field, digital_object_type: dot_item)
          durst_project.enabled_dynamic_fields << EnabledDynamicField.new(dynamic_field: dynamic_field, digital_object_type: dot_group)
          durst_project.enabled_dynamic_fields << EnabledDynamicField.new(dynamic_field: dynamic_field, digital_object_type: dot_asset)
        end

        (
          DynamicFieldGroup.find_by(string_key: 'collection').dynamic_fields +
          DynamicFieldGroup.find_by(string_key: 'form').dynamic_fields +
          DynamicFieldGroup.find_by(string_key: 'physical_location').dynamic_fields +

          DynamicFieldGroup.find_by(string_key: 'marc_005_last_modified').dynamic_fields +
          DynamicFieldGroup.find_by(string_key: 'alternative_title').dynamic_fields +
          DynamicFieldGroup.find_by(string_key: 'abstract').dynamic_fields +
          DynamicFieldGroup.find_by(string_key: 'name').dynamic_fields +
          # DynamicFieldGroup.find_by(string_key: 'name_role').dynamic_fields + # Not used for Durst
          DynamicFieldGroup.find_by(string_key: 'publisher').dynamic_fields +
          DynamicFieldGroup.find_by(string_key: 'place_of_origin').dynamic_fields +
          DynamicFieldGroup.find_by(string_key: 'date_other').dynamic_fields +
          DynamicFieldGroup.find_by(string_key: 'edition').dynamic_fields +
          DynamicFieldGroup.find_by(string_key: 'table_of_contents').dynamic_fields +
          DynamicFieldGroup.find_by(string_key: 'subject_topic').dynamic_fields +
          DynamicFieldGroup.find_by(string_key: 'subject_durst').dynamic_fields +
          DynamicFieldGroup.find_by(string_key: 'subject_temporal').dynamic_fields +
          DynamicFieldGroup.find_by(string_key: 'subject_name').dynamic_fields +
          DynamicFieldGroup.find_by(string_key: 'subject_title').dynamic_fields +
          DynamicFieldGroup.find_by(string_key: 'subject_geographic').dynamic_fields +
          DynamicFieldGroup.find_by(string_key: 'subject_hierarchical_geographic').dynamic_fields +
          DynamicFieldGroup.find_by(string_key: 'subject_hierarchical_geographic_country').dynamic_fields +
          DynamicFieldGroup.find_by(string_key: 'subject_hierarchical_geographic_province').dynamic_fields +
          DynamicFieldGroup.find_by(string_key: 'subject_hierarchical_geographic_region').dynamic_fields +
          DynamicFieldGroup.find_by(string_key: 'subject_hierarchical_geographic_state').dynamic_fields +
          DynamicFieldGroup.find_by(string_key: 'subject_hierarchical_geographic_county').dynamic_fields +
          DynamicFieldGroup.find_by(string_key: 'subject_hierarchical_geographic_borough').dynamic_fields +
          DynamicFieldGroup.find_by(string_key: 'subject_hierarchical_geographic_city').dynamic_fields +
          DynamicFieldGroup.find_by(string_key: 'subject_hierarchical_geographic_city_section').dynamic_fields +
          DynamicFieldGroup.find_by(string_key: 'subject_hierarchical_geographic_zip_code').dynamic_fields +
          DynamicFieldGroup.find_by(string_key: 'subject_hierarchical_geographic_street').dynamic_fields +
          DynamicFieldGroup.find_by(string_key: 'coordinates').dynamic_fields +
          DynamicFieldGroup.find_by(string_key: 'scale').dynamic_fields +
          DynamicFieldGroup.find_by(string_key: 'genre').dynamic_fields +
          DynamicFieldGroup.find_by(string_key: 'view_direction').dynamic_fields +
          DynamicFieldGroup.find_by(string_key: 'note').dynamic_fields +
          DynamicFieldGroup.find_by(string_key: 'extent').dynamic_fields +
          DynamicFieldGroup.find_by(string_key: 'orientation').dynamic_fields +
          DynamicFieldGroup.find_by(string_key: 'series').dynamic_fields +
          DynamicFieldGroup.find_by(string_key: 'box_title').dynamic_fields +
          DynamicFieldGroup.find_by(string_key: 'group_title').dynamic_fields +
          DynamicFieldGroup.find_by(string_key: 'clio_identifier').dynamic_fields +
          DynamicFieldGroup.find_by(string_key: 'dims_identifier').dynamic_fields +
          DynamicFieldGroup.find_by(string_key: 'durst_postcard_identifier').dynamic_fields +
          DynamicFieldGroup.find_by(string_key: 'cul_assigned_postcard_identifier').dynamic_fields +
          DynamicFieldGroup.find_by(string_key: 'isbn').dynamic_fields +
          DynamicFieldGroup.find_by(string_key: 'issn').dynamic_fields +
          DynamicFieldGroup.find_by(string_key: 'shelf_location').dynamic_fields +
          DynamicFieldGroup.find_by(string_key: 'enumeration_and_chronology').dynamic_fields +
          DynamicFieldGroup.find_by(string_key: 'sublocation').dynamic_fields +
          DynamicFieldGroup.find_by(string_key: 'url').dynamic_fields +
          DynamicFieldGroup.find_by(string_key: 'durst_favorite').dynamic_fields +
          DynamicFieldGroup.find_by(string_key: 'type_of_resource').dynamic_fields +
          DynamicFieldGroup.find_by(string_key: 'record_content_source').dynamic_fields +
          DynamicFieldGroup.find_by(string_key: 'record_origin').dynamic_fields +
          DynamicFieldGroup.find_by(string_key: 'language_of_cataloging').dynamic_fields +
          DynamicFieldGroup.find_by(string_key: 'cul_scan_note').dynamic_fields
        ).each do |dynamic_field|
          durst_project.enabled_dynamic_fields << EnabledDynamicField.new(dynamic_field: dynamic_field, digital_object_type: dot_item)
        end

      end

      task :refresh_xml_translation_rules => :environment do

        xml_datastream = XmlDatastream.find_by(string_key: 'descMetadata')
        xml_datastream.xml_translation = {
          "element" => "mods:mods",
          "attrs" => {
            "xmlns:xlink" => "http://www.w3.org/1999/xlink",
            "version" => "3.6",
            "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
            "xmlns:mods" => "http://www.loc.gov/mods/v3",
            "xsi:schemaLocation" => "http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd"
          },
          "content" => [
            {
              "yield" => "title"
            },
            {
              "yield" => "alternative_title"
            },
            {
              "yield" => "abstract"
            },
            {
              "element" => "mods:relatedItem",
              "attrs" => {
                "type" => "host",
                "displayLabel" => "Project",
              },
              "content" => [
                {
                  "element" => "mods:titleInfo",
                  "content" => [
                    {
                      "element" => "mods:title",
                      "content" => "{{$project.display_label}}"
                    }
                  ]
                }
              ]
            },
            {
              "yield" => "collection"
            },
            {
              "yield" => "coordinates"
            },
            {
              "yield" => "name"
            },
            {
              "yield" => "subject_hierarchical_geographic"
            },
            {
              "element" => "mods:originInfo",
              "content" => [
                {
                  "yield" => "publisher"
                },
                #{
                #  "yield" => "date_created"
                #},
                #{
                #  "yield" => "date_created_textual"
                #},
                #{
                #  "yield" => "date_other"
                #},
                #{
                #  "yield" => "date_other_textual"
                #},
                #{
                #  "yield" => "date_issued"
                #},
                #{
                #  "yield" => "date_issued_textual"
                #},
                {
                  "yield" => "place_of_origin"
                }
              ]
            },
            {
              "element" => "mods:physicalDescription",
              "content" => [
                {
                  "yield" => "form"
                }
              ]
            }
          ]
        }.to_json
        xml_datastream.save!

        field_group = DynamicFieldGroup.find_by(string_key: 'collection')
        field_group.xml_translation = [
          {
            "element" => "mods:relatedItem",
            "attrs" => {
              "type" => "host",
              "displayLabel" => "Collection"
            },
            "content" => [
              {
                "element" => "mods:titleInfo",
                "attrs" => {
                  "valueUri" => "{{collection_uri}}",
                  "authority" => "{{collection_authority}}",
                  "authorityUri" => "{{collection_authority_uri}}"
                },
                "content" => [
                  {
                    "element" => "mods:title",
                    "content" => "{{collection_value}}"
                  }
                ]
              }
            ]
          }
        ].to_json
        field_group.save!

        field_group = DynamicFieldGroup.find_by(string_key: 'alternative_title')
        field_group.xml_translation = [
          {
            "element" => "mods:titleInfo",
            "attrs" => {
              "type" => "alternative"
            },
            "content" => [
              {
                "element" => "mods:title",
                "content" => "{{alternative_title_sort_portion}} {{alternative_title_non_sort_portion}}"
              }
            ]
          }
        ].to_json
        field_group.save!

        field_group = DynamicFieldGroup.find_by(string_key: 'abstract')
        field_group.xml_translation = [{
          "element" => "mods:abstract",
          "content" => "{{abstract_value}}"
        }].to_json
        field_group.save!

        field_group = DynamicFieldGroup.find_by(string_key: 'name')
        field_group.xml_translation = [{
          "element" => "mods:name",
          "attrs" => {
            "type" => "{{name_type}}",
            "valueUri" => "{{name_value_uri}}",
            "authority" => "{{name_authority}}",
            "authorityUri" => "{{name_authority_uri}}"
          },
          "content" => [
            {
              "val" => "{{name_value}}"
            },
            {
              "yield" => "name_role"
            },
          ]
        }].to_json
        field_group.save!

            field_group = DynamicFieldGroup.find_by(string_key: 'name_role')
            field_group.xml_translation = [{
              "element" => "mods:role",
              "content" => [
                {
                  "element" => "mods:roleTerm",
                  "attrs" => {
                    "type" => "{{name_role_type}}",
                  },
                  "content" => "{{name_role_value}}"
                }
              ]
            }].to_json
            field_group.save!

        field_group = DynamicFieldGroup.find_by(string_key: 'publisher')
        field_group.xml_translation = [{
          "element" => "mods:publisher",
          "content" => "{{publisher_value}}"
        }].to_json
        field_group.save!

        field_group = DynamicFieldGroup.find_by(string_key: 'abstract')
        field_group.xml_translation = [{
          "element" => "mods:abstract",
          "content" => "{{abstract_value}}"
        }].to_json
        field_group.save!

        field_group = DynamicFieldGroup.find_by(string_key: 'place_of_origin')
        field_group.xml_translation = [{
          "element" => "mods:publisher",
          "content" => "{{place_of_origin_value}}"
        }].to_json
        field_group.save!

        #field_group = DynamicFieldGroup.find_by(string_key: 'date_created')
        #field_group.xml_translation = [{
        #  "render_if" => [
        #    "{{date_created_start_value}}" => "present",
        #    "{{date_created_end_value}}" => "present",
        #  ],
        #  "element" => "mods:dateCreated",
        #  "attrs" => {
        #    "encoding" => "w3cdtf"
        #  },
        #  "content" => "{{date_created_textual}}"
        #},
        #{
        #  "element" => "mods:dateCreated",
        #  "attrs" => {
        #    "encoding" => "w3cdtf"
        #  },
        #  "content" => "{{date_created_textual}}"
        #},
        #{
        #  "element" => "mods:dateCreated",
        #  "attrs" => {
        #    "encoding" => "w3cdtf"
        #  },
        #  "content" => "{{date_created_textual}}"
        #}].to_json
        #field_group.save!
        #
        #field_group = DynamicFieldGroup.find_by(string_key: 'date_created_textual')
        #field_group.xml_translation = [{
        #    "element" => "mods:dateCreated",
        #    "content" => "{{date_created_textual}}"
        #}].to_json
        #field_group.save!


        #Date Created
        #Date Created Textual
        #Date Other
        #Date Other Textual
        #Date Issued
        #Date Issued Textual
        #Edition
        #Table of Contents
        #Genre
        #Record Origin
        #
        #CLIO ID
        #DIMS ID
        #Durst Postcard Identifier
        #CUL-Assigned Postcard Identifier
        #Filename Front Identifier
        #Filename Back Identifier
        #ISBN
        #ISSN
        #

        field_group = DynamicFieldGroup.find_by(string_key: 'form')
        field_group.xml_translation = [{
          "element" => "mods:form",
          "attrs" => {
            "valueUri" => "{{form_uri}}",
            "authority" => "{{form_authority}}",
            "authorityUri" => "{{form_authority_uri}}",
          },
          "content" => [
            "{{form_value}}"
          ]
        }].to_json
        field_group.save!

        #Scale
        #Extent
        #
        #Physical Location
        #Shelf Location
        #Enumeration and Chronology
        #Sublocation
        #URL
        #
        #Subject Topic
        #Subject Durst
        #Subject Temporal
        #Subject Name
        #Subject Title
        #
        #Subject Place

        field_group = DynamicFieldGroup.find_by(string_key: 'subject_hierarchical_geographic')
        field_group.xml_translation = [{
          "element" => "mods:subject",
          "content" => [
            {
              "element" => "mods:hierarchicalGeographic",
              "content" => [
                {"yield" => "subject_hierarchical_geographic_country"},
                {"yield" => "subject_hierarchical_geographic_province"},
                {"yield" => "subject_hierarchical_geographic_region"},
                {"yield" => "subject_hierarchical_geographic_state"},
                {"yield" => "subject_hierarchical_geographic_county"},
                {"yield" => "subject_hierarchical_geographic_borough"},
                {"yield" => "subject_hierarchical_geographic_city"},
                {"yield" => "subject_hierarchical_geographic_city_section"},
                {"yield" => "subject_hierarchical_geographic_zip_code"},
                {"yield" => "subject_hierarchical_geographic_street"}
              ]
            }
          ]
        }].to_json
        field_group.save!

            field_group = DynamicFieldGroup.find_by(string_key: 'subject_hierarchical_geographic_country')
            field_group.xml_translation = [{
              "element" => "mods:country",
              "content" => "{{subject_hierarchical_geographic_country_value}}"
            }].to_json
            field_group.save!

            field_group = DynamicFieldGroup.find_by(string_key: 'subject_hierarchical_geographic_province')
            field_group.xml_translation = [{
              "element" => "mods:province",
              "content" => "{{subject_hierarchical_geographic_province_value}}"
            }].to_json
            field_group.save!

            field_group = DynamicFieldGroup.find_by(string_key: 'subject_hierarchical_geographic_region')
            field_group.xml_translation = [{
              "element" => "mods:region",
              "content" => "{{subject_hierarchical_geographic_region_value}}"
            }].to_json
            field_group.save!

            field_group = DynamicFieldGroup.find_by(string_key: 'subject_hierarchical_geographic_state')
            field_group.xml_translation = [{
              "element" => "mods:state",
              "content" => "{{subject_hierarchical_geographic_state_value}}"
            }].to_json
            field_group.save!

            field_group = DynamicFieldGroup.find_by(string_key: 'subject_hierarchical_geographic_county')
            field_group.xml_translation = [{
              "element" => "mods:county",
              "content" => "{{subject_hierarchical_geographic_county_value}}"
            }].to_json
            field_group.save!

            field_group = DynamicFieldGroup.find_by(string_key: 'subject_hierarchical_geographic_borough')
            field_group.xml_translation = [{
              "element" => "mods:citySection",
              "attrs" => {
                "citySectionType" => "borough"
              },
              "content" => "{{subject_hierarchical_geographic_borough_value}}"
            }].to_json
            field_group.save!

            field_group = DynamicFieldGroup.find_by(string_key: 'subject_hierarchical_geographic_city')
            field_group.xml_translation = [{
              "element" => "mods:city",
              "content" => "{{subject_hierarchical_geographic_city_value}}"
            }].to_json
            field_group.save!

            field_group = DynamicFieldGroup.find_by(string_key: 'subject_hierarchical_geographic_city_section')
            field_group.xml_translation = [{
              "element" => "mods:citySection",
              "content" => "{{subject_hierarchical_geographic_city_section_value}}"
            }].to_json
            field_group.save!

            field_group = DynamicFieldGroup.find_by(string_key: 'subject_hierarchical_geographic_zip_code')
            field_group.xml_translation = [{
              "element" => "mods:citySection",
              "attrs" => {
                "citySectionType" => "ZIP code"
              },
              "content" => "{{subject_hierarchical_geographic_zip_code_value}}"
            }].to_json
            field_group.save!

            field_group = DynamicFieldGroup.find_by(string_key: 'subject_hierarchical_geographic_street')
            field_group.xml_translation = [{
              "element" => "mods:citySection",
              "attrs" => {
                "citySectionType" => "Street"
              },
              "content" => "{{subject_hierarchical_geographic_street_value}}"
            }].to_json
            field_group.save!

        #Coordinates
        #
        #View Direction
        #Note
        #Orientation
        #
        #Series
        #Box Title
        #Group Title
        #
        #Record Content Source (Institutional Record Creator)
        #Language of Cataloging
        #CUL Scan Note
        #
        #Marc 005 Last Modified
        #Durst Favorite
        #Type of Resource










        field_group = DynamicFieldGroup.find_by(string_key: 'coordinates')
        field_group.xml_translation = [{
            "element" => "mods:subject",
            "content" => [
              {
                "element" => "mods:cartographics",
                "content" => [
                  {
                    "element" => "mods:coordinates",
                    "content" => "{{coordinates_value}}"
                  }
                ]
              }
            ]
        }].to_json
        field_group.save!



      end

    end
  end
end
