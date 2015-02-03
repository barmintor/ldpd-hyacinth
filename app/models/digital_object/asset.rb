class DigitalObject::Asset < DigitalObject::Base

  VALID_DC_TYPES = ['Unknown', 'Dataset', 'MovingImage', 'Software', 'Sound', 'StillImage', 'Text']
  DIGITAL_OBJECT_TYPE_STRING_KEY = 'asset'

  def initialize(*args)
    super(*args)

    # Default to 'Unknown' dc_type.  We expect other code to properly set this
    # once the asset file type is known, but this avoid a blank value for dc_type
    # and helps to identify errors when a dc_type has been improperly set.
    self.dc_type = VALID_DC_TYPES.first
  end

  # Called during before_save, after all validations have passed
  def get_new_fedora_object

    pid = self.next_pid
    generic_resource = GenericResource.new(:pid => pid)

    generic_resource.datastreams["DC"].dc_identifier = [pid]

    return generic_resource
  end

  def valid?
    super # Always run shared parent class validation

    # Assets must have at least one parent Item
    if parent_digital_object_pids.length == 0
      @errors.add(:parent_digital_object_pids, 'An Asset must have at least one parent Item')
    end

    # Assets can only be children of DigitalObject::Item objects
    parent_digital_object_pids.each {|parent_digital_object_pid|
      parent_digital_object = DigitalObject::Base.find(parent_digital_object_pid)
      unless parent_digital_object.is_a?(DigitalObject::Item)
        @errors.add(:parent_digital_object_pids, 'Assets are only allowed to be children of Items.  Found parent of type: ' + parent_digital_object.digital_object_type.display_label)
      end
    }

    return @errors.blank?
  end

  def set_file_and_original_filename_and_calculate_checksum(path_to_file, original_filename)
    # Create 'content' datastream on GenericResource object

    mime_type = DigitalObject::Asset.filename_to_mime_type(original_filename)

    # "controlGroup => 'E'" below means "External Referenced Content" -- as in, a file that's referenced by Fedora but not stored internally
    file_content_datastream = @fedora_object.create_datastream(ActiveFedora::Datastream, 'content', :controlGroup => 'E', :mimeType => mime_type, :dsLabel => original_filename, :versionable => true)
    file_content_datastream.dsLocation = 'file:' + path_to_file # Note: This will result in paths like "file:/something/here.txt"  We DO NOT want a double slash at the beginnings of these paths.

    # Calculate checksum for file, using 4096-byte buffered approach to save memory for large files
    sha256 = Digest::SHA256.new
    File.open(path_to_file, 'r') do |file|
      while buff = file.read(4096)
        sha256.update(buff)
      end
    end

    file_content_datastream.checksum = sha256.hexdigest
    file_content_datastream.checksumType = 'SHA-256'

    @fedora_object.add_datastream(file_content_datastream)
  end

  def get_filesystem_location
    content_ds = @fedora_object.datastreams['content']
    if content_ds.present?
      content_ds.dsLocation.gsub(/^file:/,'')
    else
      return nil
    end
  end

  def get_checksum
    content_ds = @fedora_object.datastreams['content']
    if content_ds.present?
      checksum = ''
      checksum += content_ds.checksumType + ':' if content_ds.checksumType
      checksum += content_ds.checksum if content_ds.checksum
      return checksum
    else
      return nil
    end
  end

  def get_original_filename
    return @fedora_object.datastreams["content"].present? ? @fedora_object.datastreams["content"].label : ''
  end

  def set_original_file_path(original_file_path)
    @fedora_object.datastreams["DC"].dc_source = original_file_path
  end

  def get_original_file_path
    return @fedora_object.datastreams["DC"].dc_source.present? ? @fedora_object.datastreams["DC"].dc_source.first : ''
  end

  def set_dc_type_based_on_filename(original_filename)

    mime_type = DigitalObject::Asset.filename_to_mime_type(original_filename)
    dc_type = 'Unknown'

    if mime_type.start_with?('image')
      dc_type = 'StillImage'
    elsif mime_type.start_with?('video')
      dc_type = 'MovingImage'
    elsif mime_type.start_with?('audio')
      dc_type = 'Sound'
    elsif mime_type.start_with?('text')
      dc_type = 'Text'
    elsif mime_type.index('excel') || mime_type.index('spreadsheet') || mime_type.index('xls') || mime_type.index('application/sql')
      dc_type = 'Dataset'
    elsif mime_type.start_with?('application')
      dc_type = 'Software'
    end

    self.dc_type = dc_type
  end

  def self.filename_to_mime_type(filename)
    detected_mime_types = MIME::Types.of(filename)
    if detected_mime_types.present?
      mime_type = MIME::Types.of(filename).first.content_type
    else
      mime_type = 'application/octet-stream' # generic catch-all for unknown content types
    end
  end

  # JSON representation
  def as_json(options={})
    json = super(options)

    json['asset_data'] = {
      filesystem_location: self.get_filesystem_location,
      checksum: self.get_checksum
    }

    return json

  end

end
