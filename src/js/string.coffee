"use strict"

$(window).on "load", ->
	for string_container in $("[data-string]")
		new StringAnimation(string_container)

reduce = (array, a, b) ->
	array.reduce(b, a)

setTimeout2 = (a, b) ->
	setTimeout(b, a)

# * Length of the string equals one.
# * Center of mass velocity is zero in all directions.
# * Since x+ equals tau, it follows that the tau derivative of
#   the center of mass of x- equals one.
# * Value of c follows.
class String
	regge_slope: 1
	tau_steps_per_fastest_revolution: 48

	constructor: (@modes) ->
		@modes[0] ||= []
		@modes[1] ||= []

		@stored_coordinates = {}
		@calculate_velocity()
		@calculate_top_mode()
		@calculate_simulation_properties()

	calculate_top_mode: ->
		@top_mode = reduce @modes, 0, (top0, modesi) ->
			top = reduce modesi, 0, (top1, mode) ->
				Math.max(top1, mode.n)
			Math.max(top0, top)

	coordinates: (tau, sigma) ->
		y_m = @y_m(tau, sigma)

		return [
			(2 * tau + y_m) / Math.sqrt(2),
			y_m / Math.sqrt(2),
			@x_i(2, tau, sigma),
			@x_i(3, tau, sigma)
		]

	coordinates_at_global_time: (t, sigma) ->
		# TODO: increse step size if time is distant
		if @stored_coordinates[sigma]
			tau_low = @stored_coordinates[sigma].tau_low
			coords_low = @stored_coordinates[sigma].coords_low
			tau_high = @stored_coordinates[sigma].tau_high
			coords_high = @stored_coordinates[sigma].coords_high
		else
			@stored_coordinates[sigma] = {}
			tau_low = tau_high = t / Math.sqrt(2)
			coords_low = coords_high = @coordinates(tau_high, sigma)

		if coords_low[0] > t
			while coords_low[0] > t
				tau_low -= @tau_increment
				coords_low = @coordinates(tau_low, sigma)
			tau_high = tau_low
			coords_high = coords_low

		iterations = 0
		while coords_high[0] < t
			tau_low = tau_high
			coords_low = coords_high
			tau_high += @tau_increment
			coords_high = @coordinates(tau_high, sigma)
			iterations += 1

		@stored_coordinates[sigma] =
			tau_low: tau_low
			coords_low: coords_low
			tau_high: tau_high
			coords_high: coords_high

		w = (t - coords_low[0]) / (coords_high[0] - coords_low[0])
		# w = 0 # test if @tau_increment is okay
		return [
			(1 - w) * coords_low[1] + w * coords_high[1]
			(1 - w) * coords_low[2] + w * coords_high[2]
			(1 - w) * coords_low[3] + w * coords_high[3]
		]


class OpenString extends String
	calculate_velocity: ->
		inverse_c_squared = 2 * @regge_slope * Math.PI * Math.PI * reduce @modes, 0, (sum, modesi) ->
			sum + reduce modesi, 0, (sum1, mode) ->
				sum1 + mode.a * mode.a + mode.b * mode.b
		@c = 1 / Math.sqrt(inverse_c_squared)

		@x_i_factor = 2 * Math.sqrt(2 * @regge_slope)
		@y_m_factor = - Math.PI * @c * 2 * @regge_slope

	calculate_simulation_properties: ->
		# Fastest contribution comes from the top mode interfering with itself
		@tau_increment = 1 / (@c * @top_mode * @tau_steps_per_fastest_revolution)

	x_i: (i, tau, sigma) ->
		vtau = Math.PI * tau * @c
		vsigma = Math.PI * sigma

		return @x_i_factor * reduce @modes[i-2], 0, (sum, mode) ->
			sum + (
				mode.a * Math.sin(mode.n * vtau) -
				mode.b * Math.cos(mode.n * vtau)
			) * Math.cos(mode.n * vsigma) / mode.n

	y_m: (tau, sigma) ->
		vtau = Math.PI * tau * @c
		vsigma = Math.PI * sigma

		return @y_m_factor * reduce @modes, 0, (sum, modesi) ->
			sum + reduce modesi, 0, (sum1, mode1) ->
				sum1 + reduce modesi, 0, (sum2, mode2) ->
					sum2 += (
						(mode1.b * mode2.a + mode1.a * mode2.b) * Math.cos((mode1.n + mode2.n) * vtau) +
						(mode1.b * mode2.b - mode1.a * mode2.a) * Math.sin((mode1.n + mode2.n) * vtau)
					) * Math.cos((mode1.n + mode2.n) * vsigma) / (mode1.n + mode2.n)
					sum2 += (
						(mode1.b * mode2.a - mode1.a * mode2.b) * Math.cos((mode1.n - mode2.n) * vtau) -
						(mode1.b * mode2.b + mode1.a * mode2.a) * Math.sin((mode1.n - mode2.n) * vtau)
					) * Math.cos((mode1.n - mode2.n) * vsigma) / (mode1.n - mode2.n) if mode1.n != mode2.n
					sum2

# For the closed string the squared amplitude of the left and right modes must be equal
class ClosedString extends String
	calculate_velocity: ->
		inverse_c_squared = 4 * @regge_slope * Math.PI * Math.PI * reduce @modes, 0, (sum, modesi) ->
			sum + reduce modesi, 0, (sum1, mode) ->
				sum1 + mode.a * mode.a + mode.b * mode.b + mode.c * mode.c + mode.d * mode.d
		@c = 1 / Math.sqrt(inverse_c_squared)

		@x_i_factor = Math.sqrt(2 * @regge_slope)
		@y_m_factor = - Math.PI * @c * 2 * @regge_slope

	calculate_simulation_properties: ->
		@tau_increment = 1 / (2 * @c * @top_mode * @tau_steps_per_fastest_revolution)

	x_i: (i, tau, sigma) ->
		vplus = 2 * Math.PI * (@c * tau + sigma)
		vminus = 2 * Math.PI * (@c * tau - sigma)

		return @x_i_factor * reduce @modes[i-2], 0, (sum, mode) ->
			sum + (
				mode.a * Math.sin(mode.n * vplus) -
				mode.b * Math.cos(mode.n * vplus) +
				mode.c * Math.sin(mode.n * vminus) -
				mode.d * Math.cos(mode.n * vminus)
			) / mode.n

	y_m: (tau, sigma) ->
		vplus = 2 * Math.PI * (@c * tau + sigma)
		vminus = 2 * Math.PI * (@c * tau - sigma)

		return @y_m_factor * reduce @modes, 0, (sum, modesi) ->
			sum + reduce modesi, 0, (sum1, mode1) ->
				sum1 + reduce modesi, 0, (sum2, mode2) ->
					sum2 += (
						(mode1.b * mode2.a + mode1.a * mode2.b) * Math.cos((mode1.n + mode2.n) * vplus) +
						(mode1.b * mode2.b - mode1.a * mode2.a) * Math.sin((mode1.n + mode2.n) * vplus)
					) / (mode1.n + mode2.n)
					sum2 += (
						(mode1.b * mode2.a - mode1.a * mode2.b) * Math.cos((mode1.n - mode2.n) * vplus) -
						(mode1.b * mode2.b + mode1.a * mode2.a) * Math.sin((mode1.n - mode2.n) * vplus)
					) / (mode1.n - mode2.n) if mode1.n != mode2.n
					sum2 += (
						(mode1.d * mode2.c + mode1.c * mode2.d) * Math.cos((mode1.n + mode2.n) * vminus) +
						(mode1.d * mode2.d - mode1.c * mode2.c) * Math.sin((mode1.n + mode2.n) * vminus)
					) / (mode1.n + mode2.n)
					sum2 += (
						(mode1.d * mode2.c - mode1.c * mode2.d) * Math.cos((mode1.n - mode2.n) * vminus) -
						(mode1.d * mode2.d + mode1.c * mode2.c) * Math.sin((mode1.n - mode2.n) * vminus)
					) / (mode1.n - mode2.n) if mode1.n != mode2.n
					sum2


class StringAnimation
	string_segments: 80

	constructor: (@container) ->
		return unless @init_display()
		@load_settings()
		@init_controls()
		@setup_rotation_control()
		@init_animation()
		@main_loop()

	init_animation: ->
		@clock = new THREE.Clock()
		@animation_time = 0

	update_string: ->
		modes = @indexed_modes.map (indexed_modesi) =>
			modesi = []
			for n of indexed_modesi
				mode = indexed_modesi[n]
				if @string_open
					modesi.push(mode) if mode.a || mode.b
				else
					modesi.push(mode) if mode.a || mode.b || mode.c || mode.d
			modesi

		@string =
			if @string_open
				new OpenString(modes)
			else
				new ClosedString(modes)

	update_site_uri: ->
		if window.history && history.replaceState
			history.replaceState(null, "", "#" + encodeURIComponent(@mode_control_textarea.value))

	get_mode: (n, i) ->
		modesi = (@indexed_modes[i-2] || {})[n]

	set_mode: (n, i, settings) ->
		modesi = @indexed_modes[i-2] ||= {}
		mode = modesi[n] ||= { n }
		$.extend(mode, settings)
		mode.a ||= 0
		mode.b ||= 0
		mode.c ||= 0
		mode.d ||= 0

	load_settings: ->
		@indexed_modes = []

		if window.location.hash && window.location.hash.length > 1
			config_string = window.location.hash
		else if window.location.search && window.location.search.length > 1
			config_string = window.location.search

		if config_string
			mode_search = /([ab])_?(\d+)_(\d+)=([-+]?\d*\.?\d+)/g
			while (match = mode_search.exec(config_string))
				kind = match[1]
				n = parseInt(match[2])
				i = parseInt(match[3])
				amplitude = parseFloat(match[4])

				settings = {}
				settings[kind] = amplitude
				@set_mode(n, i, settings)

			@string_open = not /closed/.test(config_string)
		else
			@string_open = true
			@set_mode(1, 2, { a: 0.5 })
			@set_mode(2, 2, { a: 0.5 })

	save_settings: ->
		if @string_open
			settings = ["open"]
		else
			settings = ["closed"]

		for i in [0..@indexed_modes.length-1]
			modesi = @indexed_modes[i]
			i += 2
			for n of modesi
				mode = modesi[n]
				settings.push("a" + n + "_" + i + "=" + mode.a.toFixed(2)) if mode.a
				settings.push("b" + n + "_" + i + "=" + mode.b.toFixed(2)) if mode.b
				unless @string_open
					settings.push("c" + n + "_" + i + "=" + mode.c.toFixed(2)) if mode.c
					settings.push("d" + n + "_" + i + "=" + mode.d.toFixed(2)) if mode.d

		settings = settings.join("&")

		if window.history && history.replaceState
			history.replaceState({}, "", "?" + settings)
		else
			window.location.hash = settings

	init_controls: () ->
		controls_table = $(@container).find("table[data-string-modes-table]")[0]

		max_i = 3
		max_mode = 8

		table_cells = [1..max_i].map (i) =>
			[0..max_mode].map (n) =>
				cell = document.createElement(if i == 1 || n == 0 then "th" else "td")
				if i == 1 && n == 0
					;
				else if i == 1
					cell.innerHTML = n
				else if n == 0
					cell.className = "string-mode-coordinate-cell-" + i
					cell.innerHTML = 'i = <span class="string-mode-coordinate">' + i + "</span>"
				else
					mode = @get_mode(n, i) || {}
					control = new AmplitudeControl
						max: 0.5
						size: 40
						x: mode.a
						y: mode.b
						changed: (control) =>
							@set_mode(n, i, { a: control.x, b: control.y })
							@update_string()
							@save_settings()
					cell.appendChild(control.element)
				cell

		for n in [0..max_mode]
			tr = document.createElement("tr")
			controls_table.appendChild(tr)
			for i in [2, 1, 3]
				tr.appendChild(table_cells[i-1][n])

		type_control_button = $(@container).find("button[data-string-type]")[0]
		if type_control_button
			$(type_control_button).on "click", =>
				@string_open = !@string_open
				@update_string()
				@save_settings()

		@update_string()

	show_not_supported: ->
		@display_container.innerHTML = "<p>Not possible with your browser :-(</p>"

	init_display: ->
		@display_container = $(@container).find("[data-string-display]")[0]
		@viewport_width = @display_container.clientWidth
		@viewport_height = @display_container.clientHeight

		# three.js needs addEventListener
		unless Array.prototype.reduce && window.addEventListener
			@show_not_supported()
			return false

		renderer_parameters =
			alpha: false
			stencil: false

		# TODO: use SVGRenderer?
		try
			@renderer = new THREE.WebGLRenderer(renderer_parameters)
		catch e
			try
				@renderer = new THREE.CanvasRenderer(renderer_parameters)
			catch e

		unless @renderer
			@show_not_supported()
			return false

		@renderer.autoClear = false
		@renderer.setClearColorHex(0xffffff, 1)
		@renderer.setSize(@viewport_width, @viewport_height)
		@display_container.appendChild(@renderer.domElement)

		@scene = new THREE.Scene()
		@overlay_scene = new THREE.Scene()

		material_parameters =
			color: 0
			linewidth: 1

		@string_geometry = new THREE.Geometry()
		@string_material = new THREE.LineBasicMaterial(material_parameters)
		@string_object = new THREE.Line(@string_geometry, @string_material)
		@string_object.useQuaternion = true

		@scene.add(@string_object)

		@update_scene()

		@axis_object = new THREE.Object3D()
		@axis_object.add(new THREE.ArrowHelper(new THREE.Vector3(1, 0, 0), new THREE.Vector3(), 1, 0xff0000))
		@axis_object.add(new THREE.ArrowHelper(new THREE.Vector3(0, 1, 0), new THREE.Vector3(), 1, 0x00ff00))
		@axis_object.add(new THREE.ArrowHelper(new THREE.Vector3(0, 0, 1), new THREE.Vector3(), 1, 0x0000ff))
		@axis_object.scale = new THREE.Vector3(0.15, 0.15, 0.15)
		@axis_object.position = new THREE.Vector3(1 - 0.2, 0.2 - @viewport_height / @viewport_width, 0)
		@axis_object.useQuaternion = true

		@overlay_scene.add(@axis_object)

		@camera = new THREE.PerspectiveCamera(75, @viewport_width / @viewport_height, 0.1, 1000)
		@camera.position = new THREE.Vector3(0, 0, 2)
		@camera.up = new THREE.Vector3(0, 1, 0)
		@camera.lookAt(new THREE.Vector3())

		@overlay_camera = new THREE.OrthographicCamera(-1, 1, @viewport_height / @viewport_width, -@viewport_height / @viewport_width)
		@overlay_camera.position = new THREE.Vector3(0, 0, 10)
		@overlay_camera.up = new THREE.Vector3(0, 1, 0)
		@overlay_camera.lookAt(new THREE.Vector3())

		@vertical_rotation = 0
		@horizontal_rotation = 0

		@update_camera()

		return true

	setup_rotation_control: ->
		prev_mouse_position = null

		add_click_and_drag_listener @display_container, (reason, mouse_position, e) =>
			if reason == "down"
				prev_mouse_position = mouse_position
				return
			if reason == "up"
				return
			# reason == "move"

			mouse_difference =
				x: mouse_position.x - prev_mouse_position.x
				y: mouse_position.y - prev_mouse_position.y
			prev_mouse_position = mouse_position

			@vertical_rotation += 4 * Math.PI * mouse_difference.x / @viewport_width
			@horizontal_rotation += 4 * Math.PI * mouse_difference.y / @viewport_height
			@horizontal_rotation = Math.max(@horizontal_rotation, -Math.PI / 2)
			@horizontal_rotation = Math.min(@horizontal_rotation, Math.PI / 2)

			@update_camera()

	update_camera: ->
		rotation = new THREE.Quaternion()
		rotation.setFromEuler(new THREE.Vector3(@horizontal_rotation - Math.PI / 2, 0, @vertical_rotation + Math.PI))

		@axis_object.quaternion = rotation
		@string_object.quaternion = rotation

	main_loop: ->
		window.requestAnimationFrame =>
			@main_loop()

		# Draw at least 20 frames per animated seconds 
		@animate_frame(Math.min(@clock.getDelta(), 0.05))
		@update_scene()

		@renderer.clear(true, true, false)
		@renderer.render(@scene, @camera)
		@renderer.render(@overlay_scene, @overlay_camera)

	update_scene: ->
		@string_geometry.vertices = @string_vertices
		@string_geometry.verticesNeedUpdate = true

	animate_frame: (dt) ->
		@animation_time += dt
		@string_vertices = (@string_coordinates(@animation_time, i / @string_segments) for i in [0..@string_segments])

	string_coordinates: (t, sigma) ->
		coords = @string.coordinates_at_global_time(t, sigma)
		return new THREE.Vector3(coords[1], coords[2], coords[0])

add_click_and_drag_listener = (element, callback) ->
	offset = null
	style = null

	$(element).on "mousedown", (e) =>
		e.preventDefault() # disable selecting text

		$(document).on "mousemove", mouse_move_handler
		$(document).on "mouseup", mouse_up_handler

		offset = $(element).offset()
		if window.getComputedStyle
			desired_cursor = window.getComputedStyle(element, null).cursor
			desired_cursor = "default" if !desired_cursor || desired_cursor == "auto"
			style = $('<style type="text/css">* { cursor: ' + desired_cursor + ' !important; }</style>')
		$("head").append(style) if style

		callback("down", get_pos(e), e)
		return true

	get_pos = (e) =>
		return {
			x: e.pageX - offset.left
			y: e.pageY - offset.top
		}

	mouse_move_handler = (e) =>
		callback("move", get_pos(e), e)
		return true

	mouse_up_handler = (e) =>
		$(document).off "mousemove", mouse_move_handler
		$(document).off "mouseup", mouse_up_handler

		style.detach() if style

		callback("up", get_pos(e), e)
		return true

class AmplitudeControl
	constructor: (settings = {}) ->
		@max = settings.max || 1
		@zero_snap_ratio = settings.zero_snap_value || 0.2
		@x = settings.x || 0
		@y = settings.y || 0
		@size = settings.size || 50

		@element = document.createElement("canvas")
		@element.width = @size
		@element.height = @size
		@context = @element.getContext("2d")

		@gauge_radius = (@size - 2) / 2
		@scaling = @max / @gauge_radius
		@update(@x, @y)

		add_click_and_drag_listener @element, (reason, mouse_position, e) =>
			if reason == "up"
				if settings.changed && (@initialX != @x || @initialY != @y)
					settings.changed(this)
				return
			if reason == "down"
				@initialX = @x
				@initialY = @y

			oldX = @x
			oldY = @y
			tryX = (mouse_position.x - @size / 2) * @scaling
			tryY = (@size / 2 - mouse_position.y) * @scaling
			@update(tryX, tryY, true)
			if settings.changing && (oldX != @x || oldY != @y)
				settings.changing(this)

	update: (@x, @y, snap_to_zero = false) ->
		@r = Math.sqrt(@x*@x + @y*@y)
		if @r > @max
			@x *= @max / @r
			@y *= @max / @r
			@r = @max
		if snap_to_zero && @r < @max * @zero_snap_ratio
			@x = 0
			@y = 0
			@r = 0
		if @x || @y || !@phi?
			@phi = Math.atan2(@y, @x)

		if @r == 0
			@context.strokeStyle = "#aaaaaa"
		else
			@context.strokeStyle = "rgb(" + Math.floor(@r / @max * 0xff) + ", 0, 0)"

		@context.lineWidth = 1
		@context.clearRect(0, 0, @size, @size)
		@context.beginPath()
		@context.arc(@size / 2, @size / 2, @gauge_radius, 0, 2 * Math.PI, false)
		@context.stroke()

		@context.strokeStyle = "black"
		@context.lineWidth = 2
		@context.beginPath()
		@context.moveTo(@size / 2, @size / 2)
		@context.lineTo(@size / 2 + @x / @scaling, @size / 2 - @y / @scaling)
		@context.stroke()
