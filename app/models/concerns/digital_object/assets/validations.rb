module DigitalObject::Assets::Validations
  extend ActiveSupport::Concern

  def validate
    super # Always run shared parent class validation

    # New Assets must have certain import variables set
    return @errors.blank? unless self.new_record? && pid.nil?

    validate_new_import_file_path

    validate_new_import_file_type
    # Update: Assets can be parts of filesystem objects too. Disabling this
    # check for now, but we'll get back to this later.
    ## Assets can only be children of DigitalObject::Item objects
    # parent_digital_object_pids.each {|parent_digital_object_pid|
    #  parent_digital_object = DigitalObject::Base.find(parent_digital_object_pid)
    #  unless parent_digital_object.is_a?(DigitalObject::Item)
    #    @errors.add(:parent_digital_object_pids, 'Assets are only allowed to be children of Items.  Found parent of type: ' + parent_digital_object.digital_object_type.display_label)
    #  end
    # }

    @errors.blank?
  end

  def validate_new_import_file_path
    if @import_file_import_path.blank?
      @errors.add(:import_file_import_path, 'New Assets must have @import_file_import_path set.')
    else
      # If file import path is present for this new Asset, make sure that there isn't already another Asset that is also pointing to the same file
      pid = Hyacinth::Utils::FedoraUtils.find_object_pid_by_filesystem_path(@import_file_import_path)
      @errors.add(:import_file_import_path, "Found existing Asset (#{pid}) with file path: #{@import_file_import_path}") if pid.present?
    end
  end

  def validate_new_import_file_type
    @errors.add(:import_file_import_type, 'New Assets must have @import_file_import_type set.') if @import_file_import_type.blank?

    raise "Invalid @import_file_import_type: #{@import_file_import_type.inspect}" unless DigitalObject::Asset::VALID_FILE_IMPORT_TYPES.include?(@import_file_import_type)
  end

  def validate_full_file_path(actual_path_to_validate)
    raise "No file found at path: #{actual_path_to_validate}" unless File.exist?(actual_path_to_validate)

    raise "File exists, but is not readable due to a permissions issue: #{actual_path_to_validate}" unless File.readable?(actual_path_to_validate)
  end

  def admin_required_for_type?(import_file_import_type)
    return false if DigitalObject::Asset::IMPORT_TYPE_UPLOAD_DIRECTORY == import_file_import_type
    return false if DigitalObject::Asset::IMPORT_TYPE_POST_DATA == import_file_import_type
    true
  end

  def validate_import_file_type(import_file_import_type, no_admin = false)
    raise "Missing type for import_file: digital_object_data['import_file']['import_type']" if import_file_import_type.blank?

    raise "Invalid type for import_file: digital_object_data['import_file']['import_type']: #{import_file_import_type.inspect}" unless DigitalObject::Asset::VALID_FILE_IMPORT_TYPES.include?(import_file_import_type)

    return if import_file_import_type == DigitalObject::Asset::IMPORT_TYPE_UPLOAD_DIRECTORY

    raise "Only admins can perform file imports of type: #{import_file_import_type}" if no_admin && admin_required_for_type?(import_file_import_type)
  end

  def validate_import_file_data(import_file_data)
    return unless import_file_data.present?

    import_file_import_type = import_file_data['import_type']
    validate_import_file_type(import_file_import_type)

    import_file_import_path = import_file_data['import_path']
    raise "Missing path for import_file: digital_object_data['import_file']['import_path']" if import_file_import_path.blank?

    # Make sure that the file exists and is readable
    if import_file_import_type == DigitalObject::Asset::IMPORT_TYPE_UPLOAD_DIRECTORY
      actual_path_to_validate = File.join(HYACINTH['upload_directory'], import_file_import_path)
    else
      actual_path_to_validate = import_file_import_path
    end

    validate_full_file_path(actual_path_to_validate)

    # Check for invalid characters in import path.  Reject if non-utf8.
    # If we get weird characters (like "\xC2"), Ruby will die a horrible death.  Let's keep Ruby alive.
    raise "Invalid UTF-8 characters found in file path.  Unable to upload." if import_file_import_path != Hyacinth::Utils::StringUtils.clean_utf8_string(import_file_import_path)
  end

  def log_import_file_data_errors_for_user(current_user, import_file_data_param, file_param)
    data_errors = []
    data_errors << 'Missing digital_object_data_json[import_file] for new Asset' if import_file_data_param.blank?

    import_type = import_file_data_param['import_type']

    begin
      validate_import_file_type(import_type, current_user && !current_user.admin?)
    rescue StandardError => e
      data_errors << e.message
    end

    if import_type == DigitalObject::Asset::IMPORT_TYPE_POST_DATA
      data_errors << "An attached file is required in the request data for imports of type: #{import_type}" if file_param.blank?
    end

    data_errors
  end
end
