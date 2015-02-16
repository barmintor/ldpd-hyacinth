class Project < ActiveRecord::Base

  before_create :create_associated_fedora_object!

  has_many :enabled_dynamic_fields, :dependent => :destroy
  accepts_nested_attributes_for :enabled_dynamic_fields, :allow_destroy => true

  has_many :users, :through => :project_permissions
  has_many :project_permissions, :dependent => :destroy
  accepts_nested_attributes_for :project_permissions, :allow_destroy => true, reject_if: proc { |attributes| attributes['id'].blank? && attributes['user_id'].blank? }

  belongs_to :pid_generator

  validates :display_label, :string_key, presence: true
  validate :validate_custom_asset_directory

  before_save :set_defaults_for_blank_fields
  after_save :update_fedora_object!, :ensure_that_title_fields_are_enabled_and_required

  # Returns the associated Fedora Object
  def fedora_object
    if self.pid.present?
      return @fedora_object ||= ActiveFedora::Base.find(self.pid)
    else
      return nil
    end
  end

  def next_pid
    self.pid_generator.next_pid
  end

  def create_associated_fedora_object!
    pid = self.next_pid
    concept = Concept.new(:pid => pid)
    @fedora_object = concept
    self.pid = @fedora_object.pid
  end

  def update_fedora_object!
    self.fedora_object.datastreams["DC"].dc_identifier = [pid]
    self.fedora_object.datastreams["DC"].dc_type = 'Project'
    self.fedora_object.datastreams["DC"].dc_title = self.display_label
    self.fedora_object.label = self.display_label
    self.fedora_object.save
  end

  # Returns enabled dynamic fields (with eager-loaded nested dynamic_field data because we use that frequently)
  def get_enabled_dynamic_fields(digital_object_type)
    return self.enabled_dynamic_fields.includes(:dynamic_field).where(digital_object_type: digital_object_type).to_a
  end

  def get_asset_directory
    if self.full_path_to_custom_asset_directory.present?
      self.full_path_to_custom_asset_directory
    else
      File.join(HYACINTH['default_asset_home'], self.string_key)
    end
  end

  def ensure_that_title_fields_are_enabled_and_required

    changes_require_save = false

    # For all DigitalObjectTypes that contain ANY enabled dynamic fields, ensure that the title fields are always enabled (and that title_non_sort_portion is always required)

    DigitalObjectType.all.each {|digital_object_type|
      enabled_dynamic_fields_for_type = self.enabled_dynamic_fields.select{|enabled_dynamic_field|enabled_dynamic_field.digital_object_type == digital_object_type}

      # If enabled_dynamic_fields_for_type includes the title fields, make sure that they're set as *required*
      # If not, enable them and set them as required

      # Check for presence of at least one existing enabled_dynamic_field
      if enabled_dynamic_fields_for_type.length > 0
        ensure_enabled = {
          'title_non_sort_portion' => {'required' => false},
          'title_sort_portion' => {'required' => true}
        }
        must_be_enabled = ensure_enabled.keys
        found_enabled = []

        enabled_dynamic_fields_for_type.each {|enabled_df|
          if must_be_enabled.include?(enabled_df.dynamic_field.string_key)
            found_enabled << enabled_df.dynamic_field.string_key
            if ensure_enabled[enabled_df.dynamic_field.string_key]['required'] && ! enabled_df.required
              enabled_df.required = true
              changes_require_save = true
            end
          end
        }

        (must_be_enabled - found_enabled).each {|string_key|
          self.enabled_dynamic_fields << EnabledDynamicField.new(
            dynamic_field: DynamicField.find_by(string_key: string_key),
            digital_object_type: digital_object_type,
            required: ensure_enabled[string_key]['required']
          )
          changes_require_save = true
        }
      end

    }

    save if changes_require_save

  end

  def enabled_digital_object_types
    return EnabledDynamicField.includes(:digital_object_type).select(:digital_object_type_id).distinct.where(project: self).map{|enabled_dynamic_field|enabled_dynamic_field.digital_object_type}.sort_by{|digital_object_type|digital_object_type.sort_order}
  end

  def as_json(options={})
    return {
      pid: self.pid,
      display_label: self.display_label,
      string_key: self.string_key
    }
  end

  private

  def set_defaults_for_blank_fields

  end

  def validate_custom_asset_directory
    if full_path_to_custom_asset_directory.present?

      puts 'Checking out: ' + self.get_asset_directory

      unless (File.exists?(self.get_asset_directory) &&
          File.readable?(self.get_asset_directory) &&
          File.writable?(self.get_asset_directory)
        )
        errors.add(:full_path_to_custom_asset_directory, 'could not be written to.  Ensure that the path exists and has the correct read/write permissions: "' + full_path_to_custom_asset_directory + '"')
      end
    end

  end

end
