$ ->
	minimize = ->
		# Scroll reset Makes title still appear if scrolled down before minimzed
		$('.maximized').animate(scrollTop: 0)
		.removeClass('maximized')

	# Toggles maximization on click
	$('section').click (ev) ->
		$clicked = $(this)
		if $clicked.hasClass 'maximized'
			minimize()
		else
			$clicked.addClass 'maximized'
			window.location.hash = 'nav-bar' if $(window).width() < 500

		# Prevents triggering an overall minimizing by bubbling to body click event (cf. beneath)
		ev.stopPropagation()

	# Enables links to be clicked inside a section
	$('section a').click (ev) -> ev.stopPropagation()

	# Minimizes when clicked anywhere on the page
	$('body').click minimize
	
