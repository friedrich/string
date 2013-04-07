"use strict"

window.addEventListener "load", ->
	string_containers = {}
	for string_container in document.querySelectorAll("[data-string]")
		string_name = string_container.getAttribute("data-string")
		string_containers[string_name] ||= []
		string_containers[string_name].push(string_container)

	for string_name of string_containers
		new StringAnimation(string_containers[string_name])

Array.prototype.reduce2 = (a, b) ->
	this.reduce(b, a)

setTimeout2 = (a, b) ->
	setTimeout(b, a)

class OpenString
	regge_slope: 1 / 2
	tau_steps_per_fastest_revolution: 24
	stored_coordinates: {}

	constructor: (@modes) ->
		@calculate_velocity()
		@calculate_simulation_properties()

	calculate_velocity: ->
		# set the length of the string so that @x_m_velocity = 1 and the global frame is its rest frame
		length_squared = Math.PI * Math.PI * 2 * @regge_slope * @modes.reduce2 0, (sum, modesi) ->
			sum + modesi.reduce2 0, (sum1, mode) ->
				sum1 + mode.a * mode.a + mode.b * mode.b
		@length = Math.sqrt(length_squared)

		@x_i_factor = 2 * Math.sqrt(2 * @regge_slope)
		@y_m_factor = - Math.PI / @length * 2 * @regge_slope

	calculate_simulation_properties: ->
		@top_mode = @modes.reduce2 0, (top0, modesi) ->
			top = modesi.reduce2 0, (top1, mode) ->
				Math.max(top1, mode.n)
			Math.max(top0, top)
		@tau_increment = @length / @top_mode / @tau_steps_per_fastest_revolution

	x_i: (i, tau, sigma) ->
		vtau = Math.PI * tau / @length
		vsigma = Math.PI * sigma / @length

		return @x_i_factor * @modes[i-2].reduce2 0, (sum, mode) ->
			sum + (
				mode.a * Math.sin(mode.n * vtau) -
				mode.b * Math.cos(mode.n * vtau)
			) * Math.cos(mode.n * vsigma) / mode.n

	y_m: (tau, sigma) ->
		vtau = Math.PI * tau / @length
		vsigma = Math.PI * sigma / @length

		return @y_m_factor * @modes.reduce2 0, (sum, modesi) ->
			sum + modesi.reduce2 0, (sum1, mode1) ->
				sum1 + modesi.reduce2 0, (sum2, mode2) ->
					sum2 += (
						(mode1.b * mode2.a + mode1.a * mode2.b) * Math.cos((mode1.n + mode2.n) * vtau) +
						(mode1.b * mode2.b - mode1.a * mode2.a) * Math.sin((mode1.n + mode2.n) * vtau)
					) * Math.cos((mode1.n + mode2.n) * vsigma) / (mode1.n + mode2.n)
					sum2 += (
						(mode1.b * mode2.a - mode1.a * mode2.b) * Math.cos((mode1.n - mode2.n) * vtau) -
						(mode1.b * mode2.b + mode1.a * mode2.a) * Math.sin((mode1.n - mode2.n) * vtau)
					) * Math.cos((mode1.n - mode2.n) * vsigma) / (mode1.n - mode2.n) if mode1.n != mode2.n
					sum2

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


class StringAnimation
	string_segments: 48

	constructor: (@containers) ->
		modes = [
			[	# i = 2
				{ n: 1, a: 0.5, b: 0 },
				{ n: 2, a: 0.5, b: 0 },
			],
			[	# i = 3
			],
		]
		@string = new OpenString(modes)

		@init_animation()
		@init_drawing()
		@main_loop()

	find_in_containers: (selector) ->
		@containers.reduce2 [], (list, container) ->
			for element in container.querySelectorAll(selector)
				list.push(element)
			list

	init_animation: () ->
		@clock = new THREE.Clock()

	init_drawing: () ->
		@canvas = @find_in_containers("canvas")[0]

		renderer_parameters =
			canvas: @canvas
			stencil: false

		@renderer =
			if Detector.webgl and false
				new THREE.WebGLRenderer(renderer_parameters)
			else
				new THREE.CanvasRenderer(renderer_parameters)

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
		@string_vertices = (@string_coordinates(@clock.elapsedTime, i / @string_segments * @string.length) for i in [0..@string_segments])

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
