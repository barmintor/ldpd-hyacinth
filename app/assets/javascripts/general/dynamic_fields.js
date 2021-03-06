Hyacinth.defineNamespace('Hyacinth.DynamicField');

$(document).ready(function(){
  if ($('#additional-data-json-editor').length > 0) {
    if (typeof(ace) != 'undefined') {
      var editor = ace.edit("additional-data-json-editor");
      //editor.setTheme("ace/theme/monokai");
      editor.getSession().setMode("ace/mode/json");
      var textarea = $('#additional-data-json-editor-textarea');
      textarea.hide();
      editor.getSession().setValue(textarea.val());
      editor.getSession().on('change', function(){
        textarea.val(editor.getSession().getValue());
      });
    }
  }
});
