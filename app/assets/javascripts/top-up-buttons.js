function topUpButton() {

  if( $(".product-amount").length > 0 ) {

    $(function() {
      FastClick.attach(document.body);
    });

    $('.amount-button').on('click',function(){
      var inputId = $(this).data('id');
      var price = $(this).data('price');
      var input = $('#amount-input-' + inputId);
      var total = $('#amount-total-' + inputId);
      var min = input.attr('min');
      var max = input.attr('max');
      var amount = $(this).data('operation') == "plus" ? parseInt(input.val())+1 : parseInt(input.val())-1;
      if (amount >= min && amount <= max) {
        input.val(amount);
        total.text((amount * price).toFixed(1) + "€");
      }
    });

    $('.amount-input').on('change',function(){
      var inputId = $(this).data('id');
      var price = $(this).data('price');
      var amount = $(this).val();
      var total = $('#amount-total-' + inputId);
      total.text((amount * price).toFixed(1) + "€");
    });
  }
};

$(document).on('page:load', topUpButton);
$(document).ready(topUpButton);
