Hyacinth.DigitalObjectsApp.DigitalObjectEditor = function(containerElementId, options) {

  this.$containerElement = $('#' + containerElementId);
  this.mode = options['mode'] || 'edit'; //Valid options: ['edit', 'show']
  this.digitalObject = options['digitalObject'];
  this.fieldsets = options['fieldsets'] || [];
  this.dynamicFieldHierarchy = options['dynamicFieldHierarchy'] || [];
  this.dynamicFieldIdsToEnabledDynamicFields = options['dynamicFieldIdsToEnabledDynamicFields'] || [];
  this.globalTabIndex = 0;
  this.currentAuthorizedTermSelector = null;

  //Make sure that a valid mode has been specified
  if (['edit', 'show'].indexOf(this.mode) == -1) {
    alert('Invalid editor mode: ' + this.mode);
    return;
  }

  this.init();
};

/*******************************
 *******************************
 * Class methods and variables *
 *******************************
 *******************************/

Hyacinth.DigitalObjectsApp.DigitalObjectEditor.globalTabIndex = 1; //html tabindex attributes must start with 1, not 0
Hyacinth.DigitalObjectsApp.DigitalObjectEditor.EDITOR_ELEMENT_CLASS = 'digital-object-editor';
Hyacinth.DigitalObjectsApp.DigitalObjectEditor.EDITOR_DATA_KEY = 'editor';

Hyacinth.DigitalObjectsApp.DigitalObjectEditor.getEditorInstanceForElement = function(element) {
  return $(element).closest('.' + Hyacinth.DigitalObjectsApp.DigitalObjectEditor.EDITOR_ELEMENT_CLASS).data(Hyacinth.DigitalObjectsApp.DigitalObjectEditor.EDITOR_DATA_KEY);
};

/*****************
 * Nice UI Stuff *
 *****************/

Hyacinth.DigitalObjectsApp.DigitalObjectEditor.nextGlobalTabIndex = function() {
  return Hyacinth.DigitalObjectsApp.DigitalObjectEditor.globalTabIndex++; // returns current value and then increments
};

Hyacinth.DigitalObjectsApp.DigitalObjectEditor.refreshTabIndexes = function(formElement) {
  Hyacinth.DigitalObjectsApp.DigitalObjectEditor.globalTabIndex = 1; //html tabindex attributes must start with 1, not 0
  formElement.find('.tabable').each(function(){
    $(this).attr('tabindex', Hyacinth.DigitalObjectsApp.DigitalObjectEditor.nextGlobalTabIndex());
  });
};

/**********************
 * Form Serialization *
 **********************/

Hyacinth.DigitalObjectsApp.DigitalObjectEditor.serializeFormDataToObject = function(formElement) {
  var $topLevelDynamicFieldGroups = $(formElement).children('.dynamic_field_group_content').children('.dynamic_field_group');
  var serializedData = {};
  for(var i = 0; i < $topLevelDynamicFieldGroups.length; i++) {
    var stringKey = $topLevelDynamicFieldGroups[i].getAttribute('data-string-key');
    var data = Hyacinth.DigitalObjectsApp.DigitalObjectEditor.serializeDynamicFieldGroupElement($topLevelDynamicFieldGroups[i]);
    if (typeof(serializedData[stringKey]) === 'undefined') {
      serializedData[stringKey] = [];
    }
    serializedData[stringKey].push(data);
  }
  return serializedData;
};

Hyacinth.DigitalObjectsApp.DigitalObjectEditor.serializeDynamicFieldGroupElement = function(el) {
  var serializedData = {};

  var $el = $(el);

  var $childDynamicFields = $el.children('.dynamic_field_group_content').children('.dynamic_field');
  var $childDynamicFieldGroups = $el.children('.dynamic_field_group_content').children('.dynamic_field_group');

  //Handle child dynamicFields
  for(var i = 0; i < $childDynamicFields.length; i++) {
    //Skip serializedFormAsJsonString if it's disabled.
    $dynamicFieldElement = $($childDynamicFields[i]);
    var stringKey = $dynamicFieldElement.attr('data-string-key');
    if ( $dynamicFieldElement.find('[name="' + stringKey + '"]').is(':enabled') ) {
      var data = Hyacinth.DigitalObjectsApp.DigitalObjectEditor.serializeDynamicFieldElement($dynamicFieldElement);
      serializedData[stringKey] = data;
    }
  }

  //Handle child dynamicFieldGroups
  for(var i = 0; i < $childDynamicFieldGroups.length; i++) {
    var stringKey = $childDynamicFieldGroups[i].getAttribute('data-string-key');
    var data = Hyacinth.DigitalObjectsApp.DigitalObjectEditor.serializeDynamicFieldGroupElement($childDynamicFieldGroups[i]);
    if (typeof(serializedData[stringKey]) === 'undefined') {
      serializedData[stringKey] = [];
    }
    serializedData[stringKey].push(data);
  }

  return serializedData;
};

Hyacinth.DigitalObjectsApp.DigitalObjectEditor.serializeDynamicFieldElement = function(el) {
  var $el = $(el);
  var stringKey = $el.attr('data-string-key');

  var $input = $el.find('[name="' + stringKey + '"]');

  if ($input.is(':checkbox')) {
    return $input.is(":checked"); // If we use val() on a checkbox, we'll get values like 'on' and 'off'
  } else {
    return $input.val();
  }
};


/****************************
 * AuthorizedTerm Selection *
 ****************************/

Hyacinth.DigitalObjectsApp.DigitalObjectEditor.showTermSelectorModal = function(authorizedTermField) {

  var $authorizedTermField = $(authorizedTermField);

  var editor = Hyacinth.DigitalObjectsApp.DigitalObjectEditor.getEditorInstanceForElement($authorizedTermField);

  if (editor.currentAuthorizedTermSelector != null) {
    editor.currentAuthorizedTermSelector.dispose(); //Always clean up the old instance and any event bindings it might have
    editor.currentAuthorizedTermSelector = null;
  }

  Hyacinth.showMainModal(
    'Controlled Vocabulary: ' + $authorizedTermField.attr('data-controlled-vocabulary-display-label'),
    '<div id="authorized-term-selector"></div>',
    '<button type="button" class="btn btn-default" data-dismiss="modal">Cancel</button>'
  );

  editor.currentAuthorizedTermSelector = new Hyacinth.DigitalObjectsApp.AuthorizedTermSelector('authorized-term-selector', $authorizedTermField);
};

/******************
 * Form Rendering *
 ******************/

Hyacinth.DigitalObjectsApp.DigitalObjectEditor.recursivelyRenderDynamicFieldOrDynamicFieldGroup = function(dynamic_field_or_field_group, mode, dynamicFieldIdsToEnabledDynamicFields) {

  var htmlToReturn = '';

  if (dynamic_field_or_field_group['type'] == 'DynamicField') {
    htmlToReturn += Hyacinth.DigitalObjectsApp.renderTemplate('digital_objects_app/widgets/digital_object_editor/_dynamic_field.ejs', {
      dynamic_field: dynamic_field_or_field_group,
      mode: mode,
      dynamicFieldIdsToEnabledDynamicFields: dynamicFieldIdsToEnabledDynamicFields
    });
  } else {
    //type == 'DyanmicFieldGroup'
    htmlToReturn += Hyacinth.DigitalObjectsApp.renderTemplate('digital_objects_app/widgets/digital_object_editor/_dynamic_field_group.ejs', {
      dynamic_field_group: dynamic_field_or_field_group,
      mode: mode,
      dynamicFieldIdsToEnabledDynamicFields: dynamicFieldIdsToEnabledDynamicFields
    });
  }

  return htmlToReturn;

};

Hyacinth.DigitalObjectsApp.DigitalObjectEditor.recursivelyEnsureOnlyUniqueDynamicFieldGroups = function(scopeElement) {
  var stringKeysSeenSoFar = [];
  scopeElement.find('.dynamic_field_group_content').children('.dynamic_field_group').each(function(){
    var stringKey = $(this).attr('data-string-key');
    if (stringKeysSeenSoFar.indexOf(stringKey) == -1) {
      stringKeysSeenSoFar.push(stringKey);
      Hyacinth.DigitalObjectsApp.DigitalObjectEditor.recursivelyEnsureOnlyUniqueDynamicFieldGroups($(this));
    } else {
      $(this).remove();
    }
  });
};

// Add/Remove/Reorder methods

//Creates a new DynamicFieldGroup, based on the given dynamicFieldGroupElement.  The new group coupy is placed in the DOM, after the source element.
Hyacinth.DigitalObjectsApp.DigitalObjectEditor.addDynamicFieldGroup = function(dynamicFieldGroupElement) {
  var $dynamicFieldGroup = $(dynamicFieldGroupElement);
  var $clonedElement = $dynamicFieldGroup.clone(false); //Make a copy of the element, but do not copy element data and events.
  Hyacinth.DigitalObjectsApp.DigitalObjectEditor.recursivelyEnsureOnlyUniqueDynamicFieldGroups($clonedElement); //In those cloned group, remove any dynamic fields with the same name (on the same level)
  $clonedElement.find('input, select').val(''); //Clear all form field values
  //Hyacinth.DigitalObjectsApp.DigitalObjectEditor.refreshAuthorizedTermButtonsBasedOnHiddenFieldValue($clonedElement); //Update AuthorizedTerm button display for now-cleared AuthorizedTerm fields
  $dynamicFieldGroup.after($clonedElement);
}

//Populate form with data

Hyacinth.DigitalObjectsApp.DigitalObjectEditor.populateFormElementsWithDynamicFieldData = function(dynamicFieldDataForThisLevel, containerForThisLevel, mode){

  var $containerForThisLevel = $(containerForThisLevel);

  $.each(dynamicFieldDataForThisLevel, function(stringKey, value){
    var $elementsWithStringKey = $containerForThisLevel.children('.dynamic_field_group_content').children('.dynamic_field_group, .dynamic_field').filter('[data-string-key="' + stringKey + '"]');

    if (value instanceof Array) {

      //This is a dynamicFieldGroup
      if (value.length > $elementsWithStringKey.length) {
        var $firstElement = $elementsWithStringKey.first();
        for(var i = 0; i < (value.length - $elementsWithStringKey.length); i++) {
          Hyacinth.DigitalObjectsApp.DigitalObjectEditor.addDynamicFieldGroup($firstElement);
        }
        $elementsWithStringKey = $containerForThisLevel.children('.dynamic_field_group_content').children('.dynamic_field_group, .dynamic_field').filter('[data-string-key="' + stringKey + '"]');
      }

      //We now have a 1:1 match for elements and values.  Let's populate each element with the appropriate values, via recursive function call.
      $elementsWithStringKey.each(function(index){
        Hyacinth.DigitalObjectsApp.DigitalObjectEditor.populateFormElementsWithDynamicFieldData(value[index], $(this), mode);
      });

    } else {
      //This is an individual dynamicField VALUE
      var $input = $elementsWithStringKey.find('[name="' + stringKey + '"]');

      //And in addition to setting the value, check this field if it's a checkbox with a value of true
      if ($input.is(':checkbox') && value == true) {
        $input.prop('checked', true); //We don't set a checkbox value with .val().  We want to set the checked property.
      } else {
        $input.val(value);
      }
    }

  });

};

/**********************************
 **********************************
 * Instance methods and variables *
 **********************************
 **********************************/

/*******************
 * Setup / Cleanup *
 *******************/

Hyacinth.DigitalObjectsApp.DigitalObjectEditor.prototype.init = function() {

  var that = this;

  this.$containerElement.addClass(Hyacinth.DigitalObjectsApp.DigitalObjectEditor.EDITOR_ELEMENT_CLASS); //Add class to container element
  this.$containerElement.data(Hyacinth.DigitalObjectsApp.DigitalObjectEditor.EDITOR_DATA_KEY, this); //Assign this editor object as data to the container element so that we can access it later

  //Setup form html
  this.$containerElement.html(
    Hyacinth.DigitalObjectsApp.renderTemplate('digital_objects_app/widgets/digital_object_editor/_header.ejs', {digitalObject: this.digitalObject, mode: this.mode, fieldsets: this.fieldsets}) +
    Hyacinth.DigitalObjectsApp.renderTemplate('digital_objects_app/widgets/digital_object_editor/_hierarchical_fields_form.ejs', {
      dynamicFieldHierarchy: this.dynamicFieldHierarchy,
      mode: this.mode,
      dynamicFieldIdsToEnabledDynamicFields: this.dynamicFieldIdsToEnabledDynamicFields
    })
  );

  this.$containerElement.find('.editor-form').addClass(this.mode);

  //Hide .copy-field checkboxes
  $('input.copy-field').hide();

  //Populate form with data
  var dynamicFieldDataForThisLevel = this.digitalObject.dynamic_field_data; //A bunch of dynamicFieldGroup wrappers with nested dynamicField values
  var $containerForThisLevel = this.$containerElement.find('.editor-form');
  Hyacinth.DigitalObjectsApp.DigitalObjectEditor.populateFormElementsWithDynamicFieldData(dynamicFieldDataForThisLevel, $containerForThisLevel, this.mode);

  var $editorForm = this.$containerElement.find('.editor-form');

  //Bind event handlers
  $editorForm.on('submit', function(e){

    e.preventDefault();
    var $submitButton = $(this).find('.editor-submit-button');
    $submitButton.attr('data-original-value', $submitButton.val()).val('Saving...');
    Hyacinth.addAlert('Saving...', 'info');
    $editorForm.find('.errors').html(''); //Clear existing errors
    $editorForm.find('.dynamic_field.has-error').removeClass('has-error'); //Remove current error classes

    var serializedFormAsJsonString = JSON.stringify(Hyacinth.DigitalObjectsApp.DigitalObjectEditor.serializeFormDataToObject($(this)[0]));

    var digitalObjectData = {
      digital_object_type_string_key: that.digitalObject.digital_object_type['string_key'],
      project_string_key: that.digitalObject.projects[0]['string_key'],
      dynamic_field_data_json: serializedFormAsJsonString
    };

    if (that.digitalObject.isNewRecord()) {
      digitalObjectData['parent_digital_object_pids'] = that.digitalObject.getParentDigitalObjectPids();
    }

    $.ajax({
      url: that.digitalObject.isNewRecord() ? ('/digital_objects.json') : ('/digital_objects/' + that.digitalObject.getPid() + '.json'),
      type: 'POST',
      data: {
        '_method': that.digitalObject.isNewRecord() ? 'POST' : 'PUT', //For proper RESTful Rails requests
        digital_object: digitalObjectData
      },
      cache: false
    }).done(function(digitalObjectCreationResponse){
      $submitButton.val($submitButton.attr('data-original-value'));

      if (digitalObjectCreationResponse['errors']) {
        Hyacinth.addAlert('Errors encountered during save. Please review your fields and try again.', 'danger');
        $.each(digitalObjectCreationResponse['errors'], function(error_key, error_message){
          var errorWithPossibleNumberIndicator = error_key.split('.');
          if(errorWithPossibleNumberIndicator.length > 1) {
            //This error refers to a specifically-numbered field (e.g. note_value.2)
            var stringKeyOfProblemField = errorWithPossibleNumberIndicator[0];
            var instanceNumberOfProblemField = errorWithPossibleNumberIndicator[1];
            $('.dynamic_field[data-string-key="' + stringKeyOfProblemField + '"]:eq(' + instanceNumberOfProblemField + ')').addClass('has-error');
          }
        });
        $editorForm.find('.errors').html(Hyacinth.DigitalObjectsApp.renderTemplate('digital_objects_app/widgets/digital_object_editor/_errors.ejs', {errors: digitalObjectCreationResponse['errors']}));
        Hyacinth.scrollToTopOfWindow();
      } else {
        Hyacinth.addAlert('Digital Object saved.', 'success');

        //For NEW records, upon successful save, redirect to edit view for new pid
        if (that.digitalObject.isNewRecord() ) {
          document.location.hash = Hyacinth.DigitalObjectsApp.paramsToHashValue({controller: 'digital_objects', action: 'show', pid: digitalObjectCreationResponse['pid']})
        } else {
          document.location.hash = Hyacinth.DigitalObjectsApp.paramsToHashValue({controller: 'digital_objects', action: 'show', pid: that.digitalObject.getPid() })
        }
        Hyacinth.scrollToTopOfWindow(0);
      }

    }).fail(function(){
      $submitButton.val($submitButton.attr('data-original-value'));
      alert(Hyacinth.unexpectedAjaxErrorMessage);
    });
  });

  $editorForm.on('click', '.add-dynamic-field-group', function(e){
    e.preventDefault();
    var $dynamicFieldGroup = $(this).closest('.dynamic_field_group');

    Hyacinth.DigitalObjectsApp.DigitalObjectEditor.addDynamicFieldGroup($dynamicFieldGroup);

    $dynamicFieldGroup.find('.add-dynamic-field-group').blur(); //Seems weird, but I need to do this to blur the clicked button.  Directly calling blur on the button element isn't working.
    Hyacinth.DigitalObjectsApp.DigitalObjectEditor.refreshTabIndexes($dynamicFieldGroup.closest('.editor-form'));
  });

  $editorForm.on('click', '.remove-dynamic-field-group', function(e){
    e.preventDefault();
    var $dynamicFieldGroup = $(this).closest('.dynamic_field_group');
    var stringKey = $dynamicFieldGroup.attr('data-string-key');
    //If this is the last dynamicFieldGroup of its kind within its container, create a new, blank instance before deleting the selected instance
    if ($dynamicFieldGroup.parent().children('.dynamic_field_group[data-string-key="' + stringKey + '"]').length == 1) {
      Hyacinth.DigitalObjectsApp.DigitalObjectEditor.addDynamicFieldGroup($dynamicFieldGroup);
    }
    $dynamicFieldGroup.remove();
    $dynamicFieldGroup.find('.add-dynamic-field-group').blur(); //Seems weird, but I need to do this to blur the clicked button.  Directly calling blur on the button element isn't working.
    Hyacinth.DigitalObjectsApp.DigitalObjectEditor.refreshTabIndexes($dynamicFieldGroup.closest('.editor-form'));
  });

  $editorForm.on('click', '.shift-dynamic-field-group-down', function(e){
    e.preventDefault();
    var $dynamicFieldGroup = $(this).closest('.dynamic_field_group');
    var $nextDynamicFieldGroup = $dynamicFieldGroup.next('.dynamic_field_group');
    if ($nextDynamicFieldGroup) {
      $dynamicFieldGroup.insertAfter($nextDynamicFieldGroup);
      $dynamicFieldGroup.find('.shift-dynamic-field-group-down').blur(); //Seems weird, but I need to do this to blur the clicked button.  Directly calling blur on the button element isn't working.
      Hyacinth.DigitalObjectsApp.DigitalObjectEditor.refreshTabIndexes($dynamicFieldGroup.closest('.editor-form'));
    }
  });

  $editorForm.on('click', '.shift-dynamic-field-group-up', function(e){
    e.preventDefault();
    var $dynamicFieldGroup = $(this).closest('.dynamic_field_group');
    var $prevDynamicFieldGroup = $dynamicFieldGroup.prev('.dynamic_field_group');
    if ($prevDynamicFieldGroup) {
      $prevDynamicFieldGroup.insertAfter($dynamicFieldGroup);
      $dynamicFieldGroup.find('.shift-dynamic-field-group-up').blur(); //Seems weird, but I need to do this to blur the clicked button.  Directly calling blur on the button element isn't working.
      Hyacinth.DigitalObjectsApp.DigitalObjectEditor.refreshTabIndexes($dynamicFieldGroup.closest('.editor-form'));
    }
  });

  //When in edit mode, assign default values to applicable fields
  if (this.mode == 'edit') {
    $editorForm.find('.default-value').each(function(){
      var value = $(this).attr('data-default-value');
      var $formFieldElement = $(this).parent().find('.form-field-element');
      if ($formFieldElement.val() == '') {
        $formFieldElement.val(value);
      }
    });
  }

  //Make AuthorizedTerm search buttons functional
  $editorForm.on('click', '.authorized_term_search_button', function(e){
    e.preventDefault();
    var $authorizedTermField = $(this).closest('.authorized_term').find('.authorized_term_value_field');
    Hyacinth.DigitalObjectsApp.DigitalObjectEditor.showTermSelectorModal($authorizedTermField);
  });

  if (that.mode == 'show') {
    that.removeEmptyFieldsForShowMode();
  } else {
    //edit mode
    that.removeNonEnabledNonBlankFieldsForEditMode();
  }

  // If .readonly-display-value divs are present, that means that some values should be rendered there instead of form inputs
  // This is the case for the editor 'show' mode and for locked fields in 'edit' mode
  // Render these form values in a div instead of in input fields
  var $readonlyDisplayValueElements = $editorForm.find('.readonly-display-value');
  if ($readonlyDisplayValueElements.length > 0) {
    $readonlyDisplayValueElements.each(function(){
      $dynamicFieldElement = $(this).closest('.dynamic_field');
      $formElement = $dynamicFieldElement.find('[name="' + $dynamicFieldElement.attr('data-string-key') + '"]');
      if ($formElement.is(':checkbox')) {
        $(this).html($formElement.is(":checked"));
      } else {
        $(this).html(_.escape($formElement.val()));
      }
    });
  }

  //Make fielset selector functional
  if (that.mode == 'edit' && that.$containerElement.find('.fieldset-selector').length > 0) {

    that.$containerElement.on('change', '.fieldset-selector', function(e) {

      var selectedFieldset = $(this).val();
      Hyacinth.createCookie('last_selected_fieldset', selectedFieldset, 30);

      //Show all dynamic_fields, dynamic_field_groups, dynamic_field_group_display_labels and dynamic_field_group_category_labels
      $editorForm.find('.dynamic_field, .dynamic_field_group, .dynamic_field_group_display_label, .dynamic_field_group_category_label').show();

      //Hide all dynamic_fields
      $editorForm.find('.dynamic_field').hide();
      // Show fieldset-relevant dynamic_fields
      $editorForm.find('.dynamic_field.' + selectedFieldset).each(function(){
        $(this).show();
      });

      var lastKnownNumVisibleDynamicFieldGroups = 0;
      var currentlyKnownNumVisibleDynamicFieldGroups = 0;
      while(true) {
        lastKnownNumVisibleDynamicFieldGroups = $editorForm.find('.dynamic_field_group:visible').length;

        //Hide all dynamic_field_groups that have no visible child dynamic_fields or dynamic_field_groups
        $editorForm.find('.dynamic_field_group').each(function(){
          if ($(this).children('.dynamic_field_group_content').children('.dynamic_field:visible, .dynamic_field_group:visible').length == 0) {
            $(this).hide();
          }
        });

        $editorForm.find('.dynamic_field_group_display_label').each(function(){
          if ($(this).next('.dynamic_field_group:visible').length == 0) {
            $(this).hide();
          }
        });

        $editorForm.find('.dynamic_field_group_category_label').each(function(){
          if ($(this).next('.dynamic_field_group_display_label:visible').length == 0) {
            $(this).hide();
          }
        });

        currentlyKnownNumVisibleDynamicFieldGroups = $editorForm.find('.dynamic_field_group:visible').length;

        if (currentlyKnownNumVisibleDynamicFieldGroups == lastKnownNumVisibleDynamicFieldGroups) {
          break;
        }
        lastKnownNumVisibleDynamicFieldGroups = currentlyKnownNumVisibleDynamicFieldGroups;
      }

      //Refresh navigation dropup options based on visible DynamicFieldGroupCategories
      that.refreshNavigationDropupOptions();

    });

    //And trigger the fieldset change event to set the currently visible fields
    that.$containerElement.find('.fieldset-selector').change();
  }

  //And finally, refresh tab indexes
  Hyacinth.DigitalObjectsApp.DigitalObjectEditor.refreshTabIndexes($editorForm);

  //Bind navigation dropup click handlers
  this.$containerElement.find('.form-navigation-dropup').find('.dropdown-menu').on('click', 'li', function(e){
    e.preventDefault();
    var selector = '.dynamic_field_group_category_label:contains("' + $(this).children('a').html() + '")';
    Hyacinth.scrollToElement($(selector), 400);
  });

  //Refresh navigation dropup options based on visible DynamicFieldGroupCategories
  this.refreshNavigationDropupOptions();
};

Hyacinth.DigitalObjectsApp.DigitalObjectEditor.prototype.refreshNavigationDropupOptions = function() {
  var $formNavigationDropupMenu = this.$containerElement.find('.form-navigation-dropup').find('.dropdown-menu');
  var newDropdownHtml = '';
  this.$containerElement.find('.dynamic_field_group_category_label:visible').each(function(){
    newDropdownHtml += '<li><a href="#">' + _.escape($(this).html()) + '</a></li>';
  });
  $formNavigationDropupMenu.html(newDropdownHtml);
}

//Clean up event handlers
Hyacinth.DigitalObjectsApp.DigitalObjectEditor.prototype.dispose = function() {

  this.$containerElement.removeData(Hyacinth.DigitalObjectsApp.DigitalObjectEditor.EDITOR_DATA_KEY) // Break this (circular) reference.  This is important!

  if (this.currentAuthorizedTermSelector != null) {
    this.currentAuthorizedTermSelector.dispose(); //Always clean up the old instance and any event bindings it might have
    this.currentAuthorizedTermSelector = null;
  }

  this.$containerElement.find('.form-navigation-dropup').find('.dropdown-menu').off('click');

  this.$containerElement.find('.editor-form').off('submit');
  this.$containerElement.find('.editor-form').off('click');
  this.$containerElement.off('change');
};

Hyacinth.DigitalObjectsApp.DigitalObjectEditor.prototype.removeEmptyDynamicFieldGroups = function(){
  var $editorForm = this.$containerElement.find('.editor-form');

  var foundThingsToDelete = true;
  while(foundThingsToDelete) {
    foundThingsToDelete = false;
    $editorForm.find('.dynamic_field_group').each(function(){
      if ($(this).find('.dynamic_field, .dynamic_field_group').length == 0) {
        //Found empty dynamic_field_group.  Remove it!
        $(this).remove();
        foundThingsToDelete = true;
      }
    });
  }

  // Also delete all .dynamic_field_group_display_label elements
  // that aren't immediately followed by a .dynamic_field_group element
  $editorForm.find('.dynamic_field_group_display_label').each(function(){
    if ($(this).next('.dynamic_field_group').length == 0) {
      //This dynamic_field_group_display_label's next element is NOT a dynamic_field_group.  Remove it!
      $(this).remove();
    }
  });

  // And finally, delete all .dynamic_field_group_category_label elements
  // that aren't immediately followed by a .dynamic_field_group_display_label element
  $editorForm.find('.dynamic_field_group_category_label').each(function(){
    if ($(this).next('.dynamic_field_group_display_label').length == 0) {
      //This dynamic_field_group_category_label's next element is NOT a dynamic_field_group_display_label.  Remove it!
      $(this).remove();
    }
  });
};

Hyacinth.DigitalObjectsApp.DigitalObjectEditor.prototype.removeEmptyFieldsForShowMode = function(){

  var $editorForm = this.$containerElement.find('.editor-form');

  $editorForm.find('.dynamic_field').each(function(){
    var stringKey = $(this).attr('data-string-key');
    var $input = $(this).find('[name="' + stringKey + '"]');
    if ($input.val() == '' || ($input.is(':checkbox') && ! $input.is(':checked'))) {
      //Found empty dynamic_field.  Remove it!
      $(this).remove();
    }
  });

  this.removeEmptyDynamicFieldGroups();
};

Hyacinth.DigitalObjectsApp.DigitalObjectEditor.prototype.removeNonEnabledNonBlankFieldsForEditMode = function(){

  var $editorForm = this.$containerElement.find('.editor-form');

  $editorForm.find('.dynamic_field:not(.enabled)').each(function(){
    var stringKey = $(this).attr('data-string-key');
    if ($(this).find('[name="' + stringKey + '"]').val() == '') {
      //Found NON-enabled field with empty value.  Remove it!
      $(this).remove();
    }
  });

  this.removeEmptyDynamicFieldGroups();
};
