"use strict"

window.addEventListener "load", ->
	string_containers = {}
	for string_container in document.querySelectorAll("[data-string]")
		string_name = string_container.getAttribute("data-string")
		string_containers[string_name] ||= []
		string_containers[string_name].push(string_container)

	for string_name of string_containers
		new StringAnimation(string_containers[string_name])

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
	tau_steps_per_fastest_revolution: 24

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
	string_segments: 48

	constructor: (@containers) ->
		@init_controls()
		@init_animation()
		@init_drawing()
		@main_loop()

	find_in_containers: (selector) ->
		reduce @containers, [], (list, container) ->
			for element in container.querySelectorAll(selector)
				list.push(element)
			list

	init_animation: () ->
		@clock = new THREE.Clock()
		@update_modes()

	update_modes: () ->
		modes = JSON.parse(@mode_control_textarea.value)
		@string = new OpenString(modes)

	init_controls: () ->
		@mode_control_textarea = @find_in_containers("textarea.string-modes")[0]
		@mode_control_textarea.addEventListener "blur", =>
			@update_modes()

	init_drawing: () ->
		@canvas = @find_in_containers("canvas.string-display")[0]

		renderer_parameters =
			canvas: @canvas
			stencil: false

		try
			@renderer = new THREE.WebGLRenderer(renderer_parameters)
		catch e
			try
				@renderer = new THREE.CanvasRenderer(renderer_parameters)
			catch e

		unless @renderer
			console.log("No 3d support")
			return

		@renderer.setSize(@canvas.scrollWidth, @canvas.scrollHeight)

		@scene = new THREE.Scene()

		material_parameters =
			color: 0
			linewidth: 1

		@string_geometry = new THREE.Geometry()
		@string_material = new THREE.LineBasicMaterial(material_parameters)
		@string_line = new THREE.Line(@string_geometry, @string_material)
		@scene.add(@string_line)

		@update_scene()

		@camera = new THREE.PerspectiveCamera(75, @canvas.width / @canvas.height, 0.1, 1000)
		@camera.position = new THREE.Vector3(2, 0, 0)
		@camera.up = new THREE.Vector3(0, 0, 1)
		@camera.lookAt(new THREE.Vector3(0, @camera.position.y, @camera.position.z))

	main_loop: () ->
		window.requestAnimationFrame =>
			@main_loop()
		# setTimeout2 50, =>
		# 	window.requestAnimationFrame =>
		# 		@main_loop()

		@animate_frame(@clock.getDelta())
		@update_scene()
		@renderer.render(@scene, @camera)

	update_scene: () ->
		@string_geometry.vertices = @string_vertices
		@string_geometry.verticesNeedUpdate = true

	animate_frame: (dt) ->
		# @camera.position.x += dt;
		# @camera.lookAt(new THREE.Vector3())
		@string_vertices = (@string_coordinates(@clock.elapsedTime, i / @string_segments) for i in [0..@string_segments])

		# @string_vertices = []
		# for a in [0..20]
		# 	vertices = (@string_coordinates(a * 0.05, i / @string_segments) for i in [0..@string_segments])
		# 	@string_vertices = @string_vertices.concat(vertices)

	string_coordinates: (t, sigma) ->
		coords = @string.coordinates_at_global_time(t, sigma)
		return new THREE.Vector3(coords[2], coords[0], coords[1])
		# new THREE.Vector3(
		# 	Math.sin(t) * Math.sin(2 * Math.PI * sigma) + Math.sin(2 * t) * Math.sin(8 * Math.PI * sigma),
		# 	Math.sin(t) * Math.cos(2 * Math.PI * sigma) + Math.sin(2 * t) * Math.cos(8 * Math.PI * sigma),
		# 	0
		# )
