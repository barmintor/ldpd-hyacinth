class DigitalObject::Group < DigitalObject::Base
  VALID_DC_TYPES = ['Collection']
  DIGITAL_OBJECT_TYPE_STRING_KEY = 'group'

  def initialize
    super
    self.dc_type ||= VALID_DC_TYPES.first
  end

  # Called during save, after all validations have passed
  def create_fedora_object
    Collection.new(pid: next_pid)
  end
end
