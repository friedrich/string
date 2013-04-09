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
	regge_slope: 1 / 2
	tau_steps_per_fastest_revolution: 48

	constructor: (@modes) ->
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
				sum1 + mode.a1 * mode.a1 + mode.b1 * mode.b1 + mode.a2 * mode.a2 + mode.b2 * mode.b2
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
				mode.a1 * Math.sin(mode.n * vplus) -
				mode.b1 * Math.cos(mode.n * vplus) +
				mode.a2 * Math.sin(mode.n * vminus) -
				mode.b2 * Math.cos(mode.n * vminus)
			) / mode.n

	y_m: (tau, sigma) ->
		vplus = 2 * Math.PI * (@c * tau + sigma)
		vminus = 2 * Math.PI * (@c * tau - sigma)

		return @y_m_factor * reduce @modes, 0, (sum, modesi) ->
			sum + reduce modesi, 0, (sum1, mode1) ->
				sum1 + reduce modesi, 0, (sum2, mode2) ->
					sum2 += (
						(mode1.b1 * mode2.a1 + mode1.a1 * mode2.b1) * Math.cos((mode1.n + mode2.n) * vplus) +
						(mode1.b1 * mode2.b1 - mode1.a1 * mode2.a1) * Math.sin((mode1.n + mode2.n) * vplus)
					) / (mode1.n + mode2.n)
					sum2 += (
						(mode1.b1 * mode2.a1 - mode1.a1 * mode2.b1) * Math.cos((mode1.n - mode2.n) * vplus) -
						(mode1.b1 * mode2.b1 + mode1.a1 * mode2.a1) * Math.sin((mode1.n - mode2.n) * vplus)
					) / (mode1.n - mode2.n) if mode1.n != mode2.n
					sum2 += (
						(mode1.b2 * mode2.a2 + mode1.a2 * mode2.b2) * Math.cos((mode1.n + mode2.n) * vminus) +
						(mode1.b2 * mode2.b2 - mode1.a2 * mode2.a2) * Math.sin((mode1.n + mode2.n) * vminus)
					) / (mode1.n + mode2.n)
					sum2 += (
						(mode1.b2 * mode2.a2 - mode1.a2 * mode2.b2) * Math.cos((mode1.n - mode2.n) * vminus) -
						(mode1.b2 * mode2.b2 + mode1.a2 * mode2.a2) * Math.sin((mode1.n - mode2.n) * vminus)
					) / (mode1.n - mode2.n) if mode1.n != mode2.n
					sum2


class StringAnimation
	string_segments: 64

	constructor: (@container) ->
		return unless @init_display()
		@init_controls()
		@setup_rotation_control()
		@init_animation()
		@main_loop()

	init_animation: ->
		@clock = new THREE.Clock()
		@animation_time = 0
		@update_string()

	update_string: ->
		settings = JSON.parse(@mode_control_textarea.value)
		@open_string = settings.open

		settings.modes = settings.modes.map (modesi) ->
			modesi.modes = modesi.filter (mode) ->
				if settings.open
					mode.a != 0 || mode.b != 0
				else
					mode.a1 != 0 || mode.a2 != 0 || mode.b1 != 0 || mode.b2 != 0

		@string =
			if @open_string
				new OpenString(settings.modes)
			else
				new ClosedString(settings.modes)

	update_site_uri: ->
		if window.history && history.replaceState
			history.replaceState(null, "", "#" + encodeURIComponent(@mode_control_textarea.value))

	init_controls: ->
		@mode_control_textarea = $(@container).find("[data-string-modes]")[0]
		if @mode_control_textarea
			if window.location.hash
				settings = window.location.hash.replace(/^#/, "")
				settings = decodeURIComponent(settings)
			else
				settings = '{"open": true,\n"modes": [[\n{ "n": 1, "a": 0.5, "b": 0 },\n{ "n": 2, "a": 0.5, "b": 0 }\n],[\n]]}'
			@mode_control_textarea.value = settings

			$(@mode_control_textarea).on "blur", =>
				@update_string()
				@update_site_uri()

		@type_control_button = $(@container).find("button[data-string-type]")[0]
		if @type_control_button
			$(@type_control_button).on "click", =>
				@open_string = !@open_string
				@update_string()

	show_not_supported: ->
		@display_container.innerHTML = "<p>Not possible with your browser :-(</p>"

	init_display: ->
		@display_container = $(@container).find("[data-string-display]")[0]
		@viewport_width = @display_container.clientWidth
		@viewport_height = @display_container.clientHeight

		unless Array.prototype.reduce
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
		@display_container.appendChild(@renderer.domElement);

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
		@axis_object.position = new THREE.Vector3(0.2 - 1, 0.2 - @viewport_height / @viewport_width, 0)
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
		prev_mouse_position = {}

		mouse_move_listener = (e) =>
			mouse_position = { x: e.clientX, y: e.clientY }
			mouse_difference =
				x: mouse_position.x - prev_mouse_position.x
				y: mouse_position.y - prev_mouse_position.y
			prev_mouse_position = mouse_position

			@vertical_rotation += 4 * Math.PI * mouse_difference.x / @viewport_width
			@horizontal_rotation += 4 * Math.PI * mouse_difference.y / @viewport_height
			@horizontal_rotation = Math.max(@horizontal_rotation, -Math.PI / 2)
			@horizontal_rotation = Math.min(@horizontal_rotation, Math.PI / 2)

			@update_camera()

		$(@display_container).on "mousedown", (e) =>
			prev_mouse_position = { x: e.clientX, y: e.clientY }
			$(@display_container).on "mousemove", mouse_move_listener

		$(@display_container).on "mouseup", =>
			$(@display_container).off "mousemove", mouse_move_listener
		$(@display_container).on "mouseout", =>
			$(@display_container).off "mousemove", mouse_move_listener

	update_camera: ->
		rotation = new THREE.Quaternion()
		rotation.setFromEuler(new THREE.Vector3(@horizontal_rotation, 0, @vertical_rotation))

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
		return new THREE.Vector3(coords...)
