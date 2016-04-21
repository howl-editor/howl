$(function() {
  var LS_KEY = 'howl-manual-theme';

  function updateImages(theme) {
    $('img').each(function(_, i) {
      var img = $(i);
      var res = /^(.+screenshots\/)[^\/]+(\/.+)$/.exec(img.attr('src'));
      if (res) {
        var leading = res[1];
        var shot = res[2];
        img.attr('src', leading + theme + shot);
      };
    });
  }

  $('.howl-theme-selector').show();
  $('.set-howl-theme').on('click', function(e) {
    var l = $(e.target);
    var theme = l.data('key');
    updateImages(theme);
    localStorage.setItem(LS_KEY, theme);
  });

  var theme = localStorage.getItem(LS_KEY);
  if (theme) {
    updateImages(theme);
  }
})
