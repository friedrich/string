(function() {
  "use strict";
  var OpenString, StringAnimation, reduce, setTimeout2;

  window.addEventListener("load", function() {
    var string_container, string_containers, string_name, _i, _len, _ref, _results;

    string_containers = {};
    _ref = document.querySelectorAll("[data-string]");
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      string_container = _ref[_i];
      string_name = string_container.getAttribute("data-string");
      string_containers[string_name] || (string_containers[string_name] = []);
      string_containers[string_name].push(string_container);
    }
    _results = [];
    for (string_name in string_containers) {
      _results.push(new StringAnimation(string_containers[string_name]));
    }
    return _results;
  });

  reduce = function(array, a, b) {
    return array.reduce(b, a);
  };

  setTimeout2 = function(a, b) {
    return setTimeout(b, a);
  };

  OpenString = (function() {
    OpenString.prototype.regge_slope = 1 / 2;

    OpenString.prototype.tau_steps_per_fastest_revolution = 24;

    OpenString.prototype.stored_coordinates = {};

    function OpenString(modes) {
      this.modes = modes;
      this.calculate_velocity();
      this.calculate_simulation_properties();
    }

    OpenString.prototype.calculate_velocity = function() {
      var length_squared;

      length_squared = Math.PI * Math.PI * 2 * this.regge_slope * reduce(this.modes, 0, function(sum, modesi) {
        return sum + reduce(modesi, 0, function(sum1, mode) {
          return sum1 + mode.a * mode.a + mode.b * mode.b;
        });
      });
      this.length = Math.sqrt(length_squared);
      this.x_i_factor = 2 * Math.sqrt(2 * this.regge_slope);
      return this.y_m_factor = -Math.PI / this.length * 2 * this.regge_slope;
    };

    OpenString.prototype.calculate_simulation_properties = function() {
      this.top_mode = reduce(this.modes, 0, function(top0, modesi) {
        var top;

        top = reduce(modesi, 0, function(top1, mode) {
          return Math.max(top1, mode.n);
        });
        return Math.max(top0, top);
      });
      return this.tau_increment = this.length / this.top_mode / this.tau_steps_per_fastest_revolution;
    };

    OpenString.prototype.x_i = function(i, tau, sigma) {
      var vsigma, vtau;

      vtau = Math.PI * tau / this.length;
      vsigma = Math.PI * sigma / this.length;
      return this.x_i_factor * reduce(this.modes[i - 2], 0, function(sum, mode) {
        return sum + (mode.a * Math.sin(mode.n * vtau) - mode.b * Math.cos(mode.n * vtau)) * Math.cos(mode.n * vsigma) / mode.n;
      });
    };

    OpenString.prototype.y_m = function(tau, sigma) {
      var vsigma, vtau;

      vtau = Math.PI * tau / this.length;
      vsigma = Math.PI * sigma / this.length;
      return this.y_m_factor * reduce(this.modes, 0, function(sum, modesi) {
        return sum + reduce(modesi, 0, function(sum1, mode1) {
          return sum1 + reduce(modesi, 0, function(sum2, mode2) {
            sum2 += ((mode1.b * mode2.a + mode1.a * mode2.b) * Math.cos((mode1.n + mode2.n) * vtau) + (mode1.b * mode2.b - mode1.a * mode2.a) * Math.sin((mode1.n + mode2.n) * vtau)) * Math.cos((mode1.n + mode2.n) * vsigma) / (mode1.n + mode2.n);
            if (mode1.n !== mode2.n) {
              sum2 += ((mode1.b * mode2.a - mode1.a * mode2.b) * Math.cos((mode1.n - mode2.n) * vtau) - (mode1.b * mode2.b + mode1.a * mode2.a) * Math.sin((mode1.n - mode2.n) * vtau)) * Math.cos((mode1.n - mode2.n) * vsigma) / (mode1.n - mode2.n);
            }
            return sum2;
          });
        });
      });
    };

    OpenString.prototype.coordinates = function(tau, sigma) {
      var y_m;

      y_m = this.y_m(tau, sigma);
      return [(2 * tau + y_m) / Math.sqrt(2), y_m / Math.sqrt(2), this.x_i(2, tau, sigma), this.x_i(3, tau, sigma)];
    };

    OpenString.prototype.coordinates_at_global_time = function(t, sigma) {
      var coords_high, coords_low, iterations, tau_high, tau_low, w;

      if (this.stored_coordinates[sigma]) {
        tau_low = this.stored_coordinates[sigma].tau_low;
        coords_low = this.stored_coordinates[sigma].coords_low;
        tau_high = this.stored_coordinates[sigma].tau_high;
        coords_high = this.stored_coordinates[sigma].coords_high;
      } else {
        this.stored_coordinates[sigma] = {};
        tau_low = tau_high = t / Math.sqrt(2);
        coords_low = coords_high = this.coordinates(tau_high, sigma);
      }
      if (coords_low[0] > t) {
        while (coords_low[0] > t) {
          tau_low -= this.tau_increment;
          coords_low = this.coordinates(tau_low, sigma);
        }
        tau_high = tau_low;
        coords_high = coords_low;
      }
      iterations = 0;
      while (coords_high[0] < t) {
        tau_low = tau_high;
        coords_low = coords_high;
        tau_high += this.tau_increment;
        coords_high = this.coordinates(tau_high, sigma);
        iterations += 1;
      }
      this.stored_coordinates[sigma] = {
        tau_low: tau_low,
        coords_low: coords_low,
        tau_high: tau_high,
        coords_high: coords_high
      };
      w = (t - coords_low[0]) / (coords_high[0] - coords_low[0]);
      return [(1 - w) * coords_low[1] + w * coords_high[1], (1 - w) * coords_low[2] + w * coords_high[2], (1 - w) * coords_low[3] + w * coords_high[3]];
    };

    return OpenString;

  })();

  StringAnimation = (function() {
    StringAnimation.prototype.string_segments = 48;

    function StringAnimation(containers) {
      var modes;

      this.containers = containers;
      modes = [
        [
          {
            n: 1,
            a: 0.5,
            b: 0
          }, {
            n: 2,
            a: 0.5,
            b: 0
          }
        ], []
      ];
      this.string = new OpenString(modes);
      this.init_animation();
      this.init_drawing();
      this.main_loop();
    }

    StringAnimation.prototype.find_in_containers = function(selector) {
      return reduce(this.containers, [], function(list, container) {
        var element, _i, _len, _ref;

        _ref = container.querySelectorAll(selector);
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          element = _ref[_i];
          list.push(element);
        }
        return list;
      });
    };

    StringAnimation.prototype.init_animation = function() {
      return this.clock = new THREE.Clock();
    };

    StringAnimation.prototype.init_drawing = function() {
      var material_parameters, renderer_parameters;

      this.canvas = this.find_in_containers("canvas")[0];
      renderer_parameters = {
        canvas: this.canvas,
        stencil: false
      };
      if (Modernizr.webgl) {
        this.renderer = new THREE.WebGLRenderer(renderer_parameters);
      } else if (Modernizr.canvas) {
        this.renderer = new THREE.CanvasRenderer(renderer_parameters);
      } else {
        console.log("No 3d support");
        return;
      }
      this.renderer.setSize(this.canvas.scrollWidth, this.canvas.scrollHeight);
      this.scene = new THREE.Scene();
      material_parameters = {
        color: 0,
        linewidth: 1
      };
      this.string_geometry = new THREE.Geometry();
      this.string_material = new THREE.LineBasicMaterial(material_parameters);
      this.string_line = new THREE.Line(this.string_geometry, this.string_material);
      this.scene.add(this.string_line);
      this.update_scene();
      this.camera = new THREE.PerspectiveCamera(75, this.canvas.width / this.canvas.height, 0.1, 1000);
      this.camera.position = new THREE.Vector3(2, 0, 0);
      this.camera.up = new THREE.Vector3(0, 0, 1);
      return this.camera.lookAt(new THREE.Vector3(0, this.camera.position.y, this.camera.position.z));
    };

    StringAnimation.prototype.main_loop = function() {
      var _this = this;

      window.requestAnimationFrame(function() {
        return _this.main_loop();
      });
      this.animate_frame(this.clock.getDelta());
      this.update_scene();
      return this.renderer.render(this.scene, this.camera);
    };

    StringAnimation.prototype.update_scene = function() {
      this.string_geometry.vertices = this.string_vertices;
      return this.string_geometry.verticesNeedUpdate = true;
    };

    StringAnimation.prototype.animate_frame = function(dt) {
      var i;

      return this.string_vertices = (function() {
        var _i, _ref, _results;

        _results = [];
        for (i = _i = 0, _ref = this.string_segments; 0 <= _ref ? _i <= _ref : _i >= _ref; i = 0 <= _ref ? ++_i : --_i) {
          _results.push(this.string_coordinates(this.clock.elapsedTime, i / this.string_segments * this.string.length));
        }
        return _results;
      }).call(this);
    };

    StringAnimation.prototype.string_coordinates = function(t, sigma) {
      var coords;

      coords = this.string.coordinates_at_global_time(t, sigma);
      return new THREE.Vector3(coords[2], coords[0], coords[1]);
    };

    return StringAnimation;

  })();

}).call(this);
