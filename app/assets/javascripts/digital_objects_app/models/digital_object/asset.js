// Asset - Subclass
Hyacinth.DigitalObjectsApp.DigitalObject.Asset = function(digital_object_data){
  Hyacinth.DigitalObjectsApp.DigitalObject.Base.call(this, digital_object_data); // call parent constructor
  this.assetData = digital_object_data['asset_data'];
};
Hyacinth.extendClass(Hyacinth.DigitalObjectsApp.DigitalObject.Asset, Hyacinth.DigitalObjectsApp.DigitalObject.Base); //Extend


Hyacinth.DigitalObjectsApp.DigitalObject.Base.prototype.getFilesystemLocation = function(){
  return this.assetData['filesystem_location'];
};

Hyacinth.DigitalObjectsApp.DigitalObject.Base.prototype.getFileChecksum = function(){
  return this.assetData['checksum'];
};

Hyacinth.DigitalObjectsApp.DigitalObject.Base.prototype.getFileSizeInBytes = function(){
  return this.assetData['file_size_in_bytes'];
};

Hyacinth.DigitalObjectsApp.DigitalObject.Base.prototype.getOriginalFilename = function(){
  return this.assetData['original_filename'];
};

Hyacinth.DigitalObjectsApp.DigitalObject.Base.prototype.getOriginalFilePath = function(){
  return this.assetData['original_file_path'];
};