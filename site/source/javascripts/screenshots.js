$(function() {
  var popup = $('#screenshot-popup');
  var screenshotDisplay = popup.find('.modal-body > img');
  var screenshotTitle = popup.find('.modal-title');
  var prevButton = popup.find('button.prev');
  var nextButton = popup.find('button.next');
  var screenshots = $('a.screenshot').map(function(i, link) {
    link = $(link);
    return {
      title: link.data('title'),
      href: link.attr('href')
    };
  });

  function getContext(title) {
    for (var i = 0; i < screenshots.length; ++i) {
      ss = screenshots[i];
      if (ss.title == title) {
        return {
          prev: screenshots[i - 1],
          next: screenshots[i + 1],
          cur: ss
        }
      }
    }
    return {};
  }

  function updateDisplay(ctx) {
    screenshotDisplay.attr('src', ctx.cur.href);
    screenshotTitle.text(ctx.cur.title);

    if (ctx.next) {
      nextButton.html('Next: ' + ctx.next.title);
      nextButton.data('title', ctx.next.title);
      nextButton.show();
    }
    else {
      nextButton.hide();
    }
    if (ctx.prev) {
      prevButton.html('Previous: ' + ctx.prev.title);
      prevButton.data('title', ctx.prev.title);
      prevButton.show();
    }
    else {
      prevButton.hide();
    }
  }

  function handleButtonClick(e) {
    e.preventDefault();
    var btn = $(e.target);
    var title = btn.data('title');
    var ctx = getContext(title);
    updateDisplay(ctx);
    return false;
  }

  $('a.screenshot').on('click', function(e) {
    e.preventDefault();
    var link = $(e.target).parent();
    var title = link.data('title');
    var ctx = getContext(title);
    updateDisplay(ctx);
    popup.modal('show');
    return false;
  });

  nextButton.on('click', handleButtonClick);
  prevButton.on('click', handleButtonClick);
})
