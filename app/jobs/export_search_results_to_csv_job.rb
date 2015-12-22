class ExportSearchResultsToCsvJob
  include Hyacinth::Csv::Flatten

  POINTER_SEPARATOR = Regexp.new('[-:.]')

  @queue = Hyacinth::Queue::DIGITAL_OBJECT_CSV_EXPORT

  def self.perform(csv_export_id)
    csv_export = CsvExport.find(csv_export_id)
    user = csv_export.user
    search_params = JSON.parse(csv_export.search_params)
    path_to_csv_file = File.join(HYACINTH['csv_export_directory'], "export-#{csv_export.id}-#{Time.now.strftime('%Y%m%d_%H%M%S')}.csv")

    temp_field_indexes = {}

    # Create temporary CSV file that contains data, but no headers.
    # Headers will gathere in memory, and then sorted later on.
    # Then the final CSV will be generated from the in-memory headers
    # and the temporary CSV file.
    CSV.open(path_to_csv_file + '.tmp', 'wb') do |csv|
      map_temp_field_indexes(search_params, user, temp_field_indexes) do |column_map, digital_object_data|
        headers = column_map.inject([]) do |memo, entry|
          memo[entry[1]] = Hyacinth::Csv::Fields::Base.for_header(entry[0])
        end
        # Write entire row to CSV file
        row = Hyacinth::Csv::Row.from_document(digital_object_data, headers)
        csv << row.fields
      end
    end

    sorted_column_names = temp_field_indexes.keys.sort(&ExportSearchResultsToCsvJob.method(:sort_pointers))
    write_csv(path_to_csv_file, sorted_column_names, temp_field_indexes)

    # Delete temporary CSV
    FileUtils.rm(path_to_csv_file + '.tmp')
    csv_export.path_to_csv_file = path_to_csv_file
    csv_export.save
  end

  def self.map_temp_field_indexes(search_params, user, map = {})
    map.merge!('_pid' => 0, '_project.string_key' => 1)
    DigitalObject::Base.search_in_batches(search_params, user, 50) do |digital_object_data|
      ### Handle core fields
      # identifiers
      digital_object_data.fetch('identifiers', []).size.times do |index|
        map["_identifiers-#{index + 1}"] = map.length
      end
      # publish_targets
      digital_object_data.fetch('publish_targets', []).size.times do |index|
        map["_publish_targets-#{index + 1}"] ||= map.length
      end

      # asset-only fields
      unless digital_object_data['asset_data'].blank?
        map['_asset_data.filesystem_location'] ||= map.length
        map['_asset_data.checksum'] ||= map.length
      end

      ### Handle dynamic fields
      # For controlled fields, skip the 'vocabulary_string_key' and
      # 'type' fields because they're not helpful
      flat_dynamic_fields = keys_for_document(digital_object_data, true).reject do |csv_header|
        csv_header.ends_with?('.vocabulary_string_key') ||
        csv_header.ends_with?('.type')
      end
      flat_dynamic_fields.each do |csv_header|
        map[csv_header] ||= map.length
      end

      yield map, digital_object_data if block_given?
    end
    map
  end

  def self.write_csv(path_to_csv_file, field_list, field_index_map)
    # Open new CSV for writing
    CSV.open(path_to_csv_file, 'wb') do |final_csv|
      # Write out column headers
      final_csv << field_list

      # Open temporary CSV for reading
      CSV.open(path_to_csv_file + '.tmp', 'rb') do |temp_csv|
        # Copy and reorder row data from temp csv to final csv

        temp_csv.each do |temp_csv_row|
          reordered_temp_csv_row = []
          field_list.each do |field|
            row_index = field_index_map[field]
            reordered_temp_csv_row << temp_csv_row[row_index]
          end

          final_csv << reordered_temp_csv_row
        end
      end
    end
  end

  def self.sort_pointers(a, b)
    Hyacinth::Csv::Fields::Base.for_header(a) <=> Hyacinth::Csv::Fields::Base.for_header(b)
  end
end