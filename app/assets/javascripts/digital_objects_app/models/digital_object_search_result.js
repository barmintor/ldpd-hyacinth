// Abstract DigitalObject class
Hyacinth.defineNamespace('Hyacinth.DigitalObjectsApp.DigitalObjectSearchResult');

Hyacinth.DigitalObjectsApp.DigitalObjectSearchResult = function(searchResultData) {
  this.pid = searchResultData['pid'];
  this.title = searchResultData['title_ssm'];
  this.flattenedDynamicFieldData = JSON.parse(searchResultData['flattened_dynamic_field_data_ssm'][0]);
  this.digitalObjectData = JSON.parse(searchResultData['digital_object_data_ss']);
  this.projectDisplayLabel = searchResultData['project_display_label_ssm'];
  this.digitalObjectTypeDisplayLabel = searchResultData['digital_object_type_display_label_ssm'];
  this.parentDigitalObjectPids = searchResultData['parent_digital_object_pids_ssm'] || [];
  this.orderedChildDigitalObjectPids = searchResultData['ordered_child_digital_object_pids_ssm'] || [];
  this.dcType = searchResultData['dc_type_ssm'] || '';
  this.hyacinthType = searchResultData['hyacinth_type_ssm'] || '';
};

Hyacinth.DigitalObjectsApp.DigitalObjectSearchResult.prototype.getDcType = function(){
  return this.dcType;
};

Hyacinth.DigitalObjectsApp.DigitalObjectSearchResult.prototype.getPid = function(){
  return this.pid;
};

Hyacinth.DigitalObjectsApp.DigitalObjectSearchResult.prototype.getTitle = function(){
  return this.title;
};

Hyacinth.DigitalObjectsApp.DigitalObjectSearchResult.prototype.getProjectDisplayLabel = function(){
  return this.projectDisplayLabel;
};

//Possible values include 'asset', 'item', 'group'
Hyacinth.DigitalObjectsApp.DigitalObjectSearchResult.prototype.getHyacinthType = function(){
  return this.hyacinthType;
};

Hyacinth.DigitalObjectsApp.DigitalObjectSearchResult.prototype.getDigitalObjectTypeDisplayLabel = function(){
  return this.digitalObjectTypeDisplayLabel;
};

Hyacinth.DigitalObjectsApp.DigitalObjectSearchResult.prototype.getParentDigitalObjectPids = function(){
  return this.parentDigitalObjectPids;
};

Hyacinth.DigitalObjectsApp.DigitalObjectSearchResult.prototype.getOrderedChildDigitalObjectPids = function(){
  return this.orderedChildDigitalObjectPids;
};

Hyacinth.DigitalObjectsApp.DigitalObjectSearchResult.prototype.hasImage = function() {
  return this.getHyacinthType() == 'asset' || (this.getHyacinthType() == 'item' && this.getOrderedChildDigitalObjectPids().length > 0);
}

Hyacinth.DigitalObjectsApp.DigitalObjectSearchResult.prototype.getImageUrl = function(type, size){
  if(this.getHyacinthType() == 'asset') {
    return Hyacinth.repositoryCacheUrl + '/images/' + this.getPid() + '/' + type + '/' + size + '.jpg';
  } else if (this.getHyacinthType() == 'item' && this.getOrderedChildDigitalObjectPids().length > 0) {
    return Hyacinth.repositoryCacheUrl + '/images/' + this.getOrderedChildDigitalObjectPids()[0] + '/' + type + '/' + size + '.jpg';
  } else {
    return null;
  }
};
