$(function() {
  $('input.btn-switch').bootstrapSwitch().on('switchChange.bootstrapSwitch', function(event, state) {
    var elm = $(this);
    var id = elm.data('repoid');
    var url;
    if(state)
      url = '/enable/' + id;
    else
      url = '/disable/' + id;
    elm.parents('.dashboard-row').addClass('saving');
    $.post(url, {authenticity_token: window.CSRF_TOKEN, slug: elm.data('slug')}, function(data, status, xhr) {
      elm.parents('.dashboard-row').removeClass('saving');
      if(xhr.status != 200)
        alert("Failure while saving settings. Fall down go boom.");
    });
  });
});
