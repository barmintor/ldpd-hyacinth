Hyacinth.DigitalObjectsApp.DigitalObjectEditor = function(containerElementId, options) {

  this.$containerElement = $('#' + containerElementId);
  this.mode = options['mode'] || 'edit'; //Valid options: ['edit', 'show']
  this.digitalObject = options['digitalObject'];
  this.fieldsets = options['fieldsets'] || [];
  this.dynamicFieldHierarchy = options['dynamicFieldHierarchy'] || [];
  this.dynamicFieldIdsToEnabledDynamicFields = options['dynamicFieldIdsToEnabledDynamicFields'] || [];
  this.allowedPublishTargets = options['allowedPublishTargets'] || [];
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

Hyacinth.DigitalObjectsApp.DigitalObjectEditor.showTermSelectorModal = function(controlledTermUriField, controlledTermValueDisplayElement) {

  var $controlledTermUriField = $(controlledTermUriField);
  var $controlledTermValueDisplayElement = $(controlledTermValueDisplayElement);
  
  var editor = Hyacinth.DigitalObjectsApp.DigitalObjectEditor.getEditorInstanceForElement($controlledTermUriField);

  if (editor.currentAuthorizedTermSelector != null) {
    editor.currentAuthorizedTermSelector.dispose(); //Always clean up the old instance and any event bindings it might have
    editor.currentAuthorizedTermSelector = null;
  }

  Hyacinth.showMainModal(
    'Controlled Vocabulary: ' + $controlledTermUriField.attr('data-controlled-vocabulary-display-label'),
    '<div id="authorized-term-selector"></div>',
    '<button type="button" class="btn btn-default" data-dismiss="modal">Cancel</button>'
  );

  editor.currentAuthorizedTermSelector = new Hyacinth.DigitalObjectsApp.AuthorizedTermSelector('authorized-term-selector', $controlledTermUriField, $controlledTermValueDisplayElement);
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
  $clonedElement.find('input[type!="checkbox"], select').val(''); //Clear all form field values (except checkboxes, which should not have their value attributes cleared)
  $clonedElement.find('input[type="checkbox"]').prop('checked', false); //Uncheck check boxes
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

      //Set the value, handling checkboxes accordingly
      if ($input.is(':checkbox') && value == true) {
        $input.prop('checked', true); //We don't set a checkbox value with .val().  We want to set the checked property.
      } else if($input.hasClass('controlled_term_uri_field')) {
        $input.val(value['uri']); //Set uri as hidden field value
        $controlledTermFieldWrapperElement = $input.closest('.controlled_term_field');
        $controlledTermFieldWrapperElement.find('.controlled_term_value_display').html(value['value']); //Set value as display value
        $controlledTermFieldWrapperElement.find('.controlled_term_clear_button').removeClass('hidden'); //Show controlled_term_clear_button so that value can be cleared
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
      dynamicFieldIdsToEnabledDynamicFields: this.dynamicFieldIdsToEnabledDynamicFields,
      digitalObject: this.digitalObject,
      allowedPublishTargets: this.allowedPublishTargets
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
    that.submitEditorForm(false);
  });

  $editorForm.on('click', '.editor-submit-button', function(e){
    e.preventDefault();
    that.submitEditorForm(false);
  });

  $editorForm.on('click', '.editor-submit-and-publish-button', function(e){
    e.preventDefault();
    that.submitEditorForm(true);
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
  
  //Populate values (based on URIs) for all controlled_term_field elements
  this.populateValuesForControlledTermFields(function(){
    //Make AuthorizedTerm search buttons functional
    $editorForm.on('click', '.authorized_term_search_button', function(e){
      e.preventDefault();
      var $controlledTermUriField = $(this).closest('.controlled_term_field').find('.controlled_term_uri_field');
      var $controlledTermValueDisplayElement = $(this).closest('.controlled_term_field').find('.controlled_term_value_display');
      Hyacinth.DigitalObjectsApp.DigitalObjectEditor.showTermSelectorModal($controlledTermUriField, $controlledTermValueDisplayElement);
    });
    
    //Make AuthorizedTerm clear button functional
    $editorForm.on('click', '.controlled_term_clear_button', function(e){
      e.preventDefault();
      var $controlledTermUriField = $(this).closest('.controlled_term_field').find('.controlled_term_uri_field');
      var $controlledTermValueDisplayElement = $(this).closest('.controlled_term_field').find('.controlled_term_value_display');
      $controlledTermUriField.val('');
      $controlledTermValueDisplayElement.html('- Select a value -');
      $(this).addClass('hidden');
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
        } else if ($formElement.hasClass('controlled_term_uri_field')) {
          console.log($formElement.closest('.controlled_term_field').find('.controlled_term_value_display'));
          $(this).html($formElement.closest('.controlled_term_field').find('.controlled_term_value_display').html());
        } else {
          $(this).html(_.escape($formElement.val()).replace(/(?:\r\n|\r|\n)/g, '<br />'));
        }
      });
    }
  
    //Make fieldset selector functional
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
  
    if (that.digitalObject instanceof Hyacinth.DigitalObjectsApp.DigitalObject.Asset) {
      $('.rotate-dropdown-options li a').on('click', function(e){
        e.preventDefault();
        var rotateBy = parseInt($(this).attr('data-rotate-by'));
        var $thumbnailImg = $(this).closest('.child-digital-object-preview').find('img.thumbnail');
        $thumbnailImg.css('opacity', '.3');
        Hyacinth.addAlert('Rotating image...', 'info');
        $.ajax({
          url: '/digital_objects/' + that.digitalObject.getPid() + '/rotate_image',
          type: 'POST',
          data: {
            rotate_by: rotateBy
          },
          cache: false
        }).done(function(rotationResponse){
          $thumbnailImg.css('opacity', '1');
          if (rotationResponse['success']) {
            $thumbnailImg.attr('src', $thumbnailImg.attr('src') + '?' + new Date().getTime());
            Hyacinth.addAlert('Image has been rotated and queued for derivative regeneration.<br /><br /><strong>Note:</strong> A hard page refresh will be required to view the change globally (because of browser caching).', 'info');
          } else {
            Hyacinth.addAlert('An error occurred during the rotation attempt:<br />' + rotationResponse['errors'].join(', '), 'danger');
          }
        }).fail(function(){
          alert(Hyacinth.unexpectedAjaxErrorMessage);
        });
      });
    }
  
    //And finally, refresh tab indexes
    Hyacinth.DigitalObjectsApp.DigitalObjectEditor.refreshTabIndexes($editorForm);
  
    //Bind navigation dropup click handlers
    that.$containerElement.find('.form-navigation-dropup').find('.dropdown-menu').on('click', 'li', function(e){
      e.preventDefault();
      var selector = '.dynamic_field_group_category_label:contains("' + $(this).children('a').html() + '")';
      Hyacinth.scrollToElement($(selector), 400, function(){
        $(selector).addClass("highlightPageElement");
      });
    });
  
    //Refresh navigation dropup options based on visible DynamicFieldGroupCategories
    that.refreshNavigationDropupOptions();
  });

};

Hyacinth.DigitalObjectsApp.DigitalObjectEditor.prototype.populateValuesForControlledTermFields = function(callback) {
  
  //Collect list of URIs
  var listOfUris = [];
  this.$containerElement.find('.controlled_term_field[data-initialized="false"]').find('.controlled_term_uri_field').each(function(){
    //console.log($(this));
    listOfUris = $(this).val();
  });
  
  //console.log('found:' + listOfUris);
  
  //Resolve URIs to values
  
  //Apply values to URI fields
  this.$containerElement.find('.controlled_term_field[data-initialized="false"]').find('.controlled_term_uri_field').each(function(){
    
  });
  
  callback();
}


Hyacinth.DigitalObjectsApp.DigitalObjectEditor.prototype.submitEditorForm = function(publish) {

  var $editorForm = this.$containerElement.find('.editor-form');

  Hyacinth.addAlert('Saving...', 'info');
  $editorForm.find('.errors').html(''); //Clear existing errors
  $editorForm.find('.dynamic_field.has-error').removeClass('has-error'); //Remove current error classes

  var publishTargets = null;
  $editorForm.find('.publish-targets .publish-target-checkbox').each(function(){
    if ($(this).prop('checked')) {
      if (publishTargets == null) {
        publishTargets = [];
      }
      publishTargets.push({pid: $(this).val()})
    }
  });

  var digitalObjectData = {
    digital_object_type: {string_key: this.digitalObject.digital_object_type['string_key']},
    dynamic_field_data: Hyacinth.DigitalObjectsApp.DigitalObjectEditor.serializeFormDataToObject($editorForm),
    publish_targets: publishTargets
  };

  if (this.digitalObject.isNewRecord()) {
    digitalObjectData['project'] = {string_key: this.digitalObject.project['string_key']};
    digitalObjectData['parent_digital_objects'] = $.map(this.digitalObject.getParentDigitalObjectPids(), function(val){ return {pid: val} });
  }

  var that = this;

  $.ajax({
    url: this.digitalObject.isNewRecord() ? ('/digital_objects.json') : ('/digital_objects/' + this.digitalObject.getPid() + '.json'),
    type: 'POST',
    data: {
      '_method': this.digitalObject.isNewRecord() ? 'POST' : 'PUT', //For proper RESTful Rails requests
      digital_object_data_json: JSON.stringify(digitalObjectData),
      publish: publish
    },
    cache: false
  }).done(function(digitalObjectCreationResponse){

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
      Hyacinth.addAlert('Digital Object saved' + (publish ? ' and <strong>published</strong>.' : '.'), 'success');

      //For NEW records, upon successful save, redirect to edit view for new pid
      if ( that.digitalObject.isNewRecord() ) {
        document.location.hash = Hyacinth.DigitalObjectsApp.paramsToHashValue({controller: 'digital_objects', action: 'show', pid: digitalObjectCreationResponse['pid']})
      } else {
        document.location.hash = Hyacinth.DigitalObjectsApp.paramsToHashValue({controller: 'digital_objects', action: 'show', pid: that.digitalObject.getPid() })
      }
      Hyacinth.scrollToTopOfWindow(0);
    }

  }).fail(function(){
    alert(Hyacinth.unexpectedAjaxErrorMessage);
  });
}

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

    var $input = $(this).find('[name="' + stringKey + '"]');
    if ($input.val() == '' || ($input.is(':checkbox') && ! $input.is(':checked'))) {
      //Found NON-enabled field with empty value.  Remove it!
      $(this).remove();
    }
  });

  this.removeEmptyDynamicFieldGroups();
};


Hyacinth.DigitalObjectsApp.DigitalObjectEditor.attemptToRefreshCacheForImageUrl = function(url, callback) {
  //var i = new Image();
  //i.src = url + '?' + new Date().getTime();
  //var $newDiv = $('<div style="display:none;"></div>');
  //$newDiv.append(i);
  //$('body').append($newDiv);
  //i.onload = function(){
  //  callback();
  //  $newDiv.remove();
  //};


  $.get( url, function( data ) {
    callback();
  });

};
