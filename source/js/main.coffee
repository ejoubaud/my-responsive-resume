$ ->
  minimize = ->
    # Scroll reset Makes title still appear if scrolled down before minimzed
    $('.maximized').animate(scrollTop: 0)
    .removeClass('maximized')

  scroll_to = (selector) ->
    $(document.body).animate
      scrollTop: $(selector).offset().top,
      500

  # Toggles maximization on click
  $('section').click (ev) ->
    $clicked = $(this)
    scroll_to '#nav-bar' if $(window).width() < 500
    if $('.maximized').length > 0
      minimize()
    else
      $clicked.addClass 'maximized'

    # Prevents triggering an overall minimizing by bubbling to body click event (cf. beneath)
    ev.stopPropagation()

  # Enables links to be clicked inside a section
  $('section a').click (ev) -> ev.stopPropagation()

  # Minimizes when clicked anywhere on the page
  $('body').click minimize
  

  # Smoothes scrolling on nav links
  $('.nav-link').click (e) ->
    e.preventDefault()
    scroll_to @hash
