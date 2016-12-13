function UpdateFlagFormValue() {
  $(".collection_check_boxes").click(function() {
    var att = $(this).attr('for');
    var input = $("#" + att);
    input.prop('value', input.val() !== "true");
  });
}
$(document).on('page:load', UpdateFlagFormValue);
$(document).ready(UpdateFlagFormValue);
