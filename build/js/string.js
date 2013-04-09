(function() {
  "use strict";
  var ClosedString, OpenString, String, StringAnimation, reduce, setTimeout2, _ref, _ref1,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

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

  String = (function() {
    String.prototype.regge_slope = 1 / 2;

    String.prototype.tau_steps_per_fastest_revolution = 48;

    function String(modes) {
      this.modes = modes;
      this.stored_coordinates = {};
      this.calculate_velocity();
      this.calculate_top_mode();
      this.calculate_simulation_properties();
    }

    String.prototype.calculate_top_mode = function() {
      return this.top_mode = reduce(this.modes, 0, function(top0, modesi) {
        var top;

        top = reduce(modesi, 0, function(top1, mode) {
          return Math.max(top1, mode.n);
        });
        return Math.max(top0, top);
      });
    };

    String.prototype.coordinates = function(tau, sigma) {
      var y_m;

      y_m = this.y_m(tau, sigma);
      return [(2 * tau + y_m) / Math.sqrt(2), y_m / Math.sqrt(2), this.x_i(2, tau, sigma), this.x_i(3, tau, sigma)];
    };

    String.prototype.coordinates_at_global_time = function(t, sigma) {
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

    return String;

  })();

  OpenString = (function(_super) {
    __extends(OpenString, _super);

    function OpenString() {
      _ref = OpenString.__super__.constructor.apply(this, arguments);
      return _ref;
    }

    OpenString.prototype.calculate_velocity = function() {
      var inverse_c_squared;

      inverse_c_squared = 2 * this.regge_slope * Math.PI * Math.PI * reduce(this.modes, 0, function(sum, modesi) {
        return sum + reduce(modesi, 0, function(sum1, mode) {
          return sum1 + mode.a * mode.a + mode.b * mode.b;
        });
      });
      this.c = 1 / Math.sqrt(inverse_c_squared);
      this.x_i_factor = 2 * Math.sqrt(2 * this.regge_slope);
      return this.y_m_factor = -Math.PI * this.c * 2 * this.regge_slope;
    };

    OpenString.prototype.calculate_simulation_properties = function() {
      return this.tau_increment = 1 / (this.c * this.top_mode * this.tau_steps_per_fastest_revolution);
    };

    OpenString.prototype.x_i = function(i, tau, sigma) {
      var vsigma, vtau;

      vtau = Math.PI * tau * this.c;
      vsigma = Math.PI * sigma;
      return this.x_i_factor * reduce(this.modes[i - 2], 0, function(sum, mode) {
        return sum + (mode.a * Math.sin(mode.n * vtau) - mode.b * Math.cos(mode.n * vtau)) * Math.cos(mode.n * vsigma) / mode.n;
      });
    };

    OpenString.prototype.y_m = function(tau, sigma) {
      var vsigma, vtau;

      vtau = Math.PI * tau * this.c;
      vsigma = Math.PI * sigma;
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

    return OpenString;

  })(String);

  ClosedString = (function(_super) {
    __extends(ClosedString, _super);

    function ClosedString() {
      _ref1 = ClosedString.__super__.constructor.apply(this, arguments);
      return _ref1;
    }

    ClosedString.prototype.calculate_velocity = function() {
      var inverse_c_squared;

      inverse_c_squared = 4 * this.regge_slope * Math.PI * Math.PI * reduce(this.modes, 0, function(sum, modesi) {
        return sum + reduce(modesi, 0, function(sum1, mode) {
          return sum1 + mode.a1 * mode.a1 + mode.b1 * mode.b1 + mode.a2 * mode.a2 + mode.b2 * mode.b2;
        });
      });
      this.c = 1 / Math.sqrt(inverse_c_squared);
      this.x_i_factor = Math.sqrt(2 * this.regge_slope);
      return this.y_m_factor = -Math.PI * this.c * 2 * this.regge_slope;
    };

    ClosedString.prototype.calculate_simulation_properties = function() {
      return this.tau_increment = 1 / (2 * this.c * this.top_mode * this.tau_steps_per_fastest_revolution);
    };

    ClosedString.prototype.x_i = function(i, tau, sigma) {
      var vminus, vplus;

      vplus = 2 * Math.PI * (this.c * tau + sigma);
      vminus = 2 * Math.PI * (this.c * tau - sigma);
      return this.x_i_factor * reduce(this.modes[i - 2], 0, function(sum, mode) {
        return sum + (mode.a1 * Math.sin(mode.n * vplus) - mode.b1 * Math.cos(mode.n * vplus) + mode.a2 * Math.sin(mode.n * vminus) - mode.b2 * Math.cos(mode.n * vminus)) / mode.n;
      });
    };

    ClosedString.prototype.y_m = function(tau, sigma) {
      var vminus, vplus;

      vplus = 2 * Math.PI * (this.c * tau + sigma);
      vminus = 2 * Math.PI * (this.c * tau - sigma);
      return this.y_m_factor * reduce(this.modes, 0, function(sum, modesi) {
        return sum + reduce(modesi, 0, function(sum1, mode1) {
          return sum1 + reduce(modesi, 0, function(sum2, mode2) {
            sum2 += ((mode1.b1 * mode2.a1 + mode1.a1 * mode2.b1) * Math.cos((mode1.n + mode2.n) * vplus) + (mode1.b1 * mode2.b1 - mode1.a1 * mode2.a1) * Math.sin((mode1.n + mode2.n) * vplus)) / (mode1.n + mode2.n);
            if (mode1.n !== mode2.n) {
              sum2 += ((mode1.b1 * mode2.a1 - mode1.a1 * mode2.b1) * Math.cos((mode1.n - mode2.n) * vplus) - (mode1.b1 * mode2.b1 + mode1.a1 * mode2.a1) * Math.sin((mode1.n - mode2.n) * vplus)) / (mode1.n - mode2.n);
            }
            sum2 += ((mode1.b2 * mode2.a2 + mode1.a2 * mode2.b2) * Math.cos((mode1.n + mode2.n) * vminus) + (mode1.b2 * mode2.b2 - mode1.a2 * mode2.a2) * Math.sin((mode1.n + mode2.n) * vminus)) / (mode1.n + mode2.n);
            if (mode1.n !== mode2.n) {
              sum2 += ((mode1.b2 * mode2.a2 - mode1.a2 * mode2.b2) * Math.cos((mode1.n - mode2.n) * vminus) - (mode1.b2 * mode2.b2 + mode1.a2 * mode2.a2) * Math.sin((mode1.n - mode2.n) * vminus)) / (mode1.n - mode2.n);
            }
            return sum2;
          });
        });
      });
    };

    return ClosedString;

  })(String);

  StringAnimation = (function() {
    StringAnimation.prototype.string_segments = 64;

    function StringAnimation(containers) {
      this.containers = containers;
      this.init_controls();
      this.init_animation();
      this.init_drawing();
      this.main_loop();
    }

    StringAnimation.prototype.find_in_containers = function(selector) {
      return reduce(this.containers, [], function(list, container) {
        var element, _i, _len, _ref2;

        _ref2 = container.querySelectorAll(selector);
        for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
          element = _ref2[_i];
          list.push(element);
        }
        return list;
      });
    };

    StringAnimation.prototype.init_animation = function() {
      this.clock = new THREE.Clock();
      this.animation_time = 0;
      return this.update_string();
    };

    StringAnimation.prototype.update_string = function() {
      var settings;

      settings = JSON.parse(this.mode_control_textarea.value);
      this.open_string = settings.open;
      settings.modes = settings.modes.map(function(modesi) {
        return modesi.modes = modesi.filter(function(mode) {
          if (settings.open) {
            return mode.a !== 0 || mode.b !== 0;
          } else {
            return mode.a1 !== 0 || mode.a2 !== 0 || mode.b1 !== 0 || mode.b2 !== 0;
          }
        });
      });
      return this.string = this.open_string ? new OpenString(settings.modes) : new ClosedString(settings.modes);
    };

    StringAnimation.prototype.update_site_uri = function() {
      if (window.history && history.replaceState) {
        return history.replaceState(null, "", "#" + encodeURIComponent(this.mode_control_textarea.value));
      }
    };

    StringAnimation.prototype.init_controls = function() {
      var settings,
        _this = this;

      this.mode_control_textarea = this.find_in_containers("textarea.string-modes")[0];
      if (this.mode_control_textarea) {
        if (window.location.hash) {
          settings = window.location.hash.replace(/^#/, "");
          settings = decodeURIComponent(settings);
        } else {
          settings = '{"open": true,\n"modes": [[\n{ "n": 1, "a": 0.5, "b": 0 },\n{ "n": 2, "a": 0.5, "b": 0 }\n],[\n]]}';
        }
        this.mode_control_textarea.value = settings;
        this.mode_control_textarea.addEventListener("blur", function() {
          _this.update_string();
          return _this.update_site_uri();
        });
      }
      this.type_control_button = this.find_in_containers("button.string-type")[0];
      if (this.type_control_button) {
        return this.type_control_button.addEventListener("click", function() {
          _this.open_string = !_this.open_string;
          return _this.update_string();
        });
      }
    };

    StringAnimation.prototype.init_drawing = function() {
      var e, material_parameters, renderer_parameters;

      this.display_container = this.find_in_containers(".string-display")[0];
      this.viewport_width = this.display_container.clientWidth;
      this.viewport_height = this.display_container.clientHeight;
      renderer_parameters = {
        alpha: false,
        stencil: false
      };
      try {
        this.renderer = new THREE.WebGLRenderer(renderer_parameters);
      } catch (_error) {
        e = _error;
        try {
          this.renderer = new THREE.CanvasRenderer(renderer_parameters);
        } catch (_error) {
          e = _error;
        }
      }
      if (!this.renderer) {
        console.log("No 3d support");
        return;
      }
      this.renderer.autoClear = false;
      this.renderer.setClearColorHex(0xffffff, 1);
      this.renderer.setSize(this.viewport_width, this.viewport_height);
      this.display_container.appendChild(this.renderer.domElement);
      this.scene = new THREE.Scene();
      this.overlay_scene = new THREE.Scene();
      material_parameters = {
        color: 0,
        linewidth: 1
      };
      this.string_geometry = new THREE.Geometry();
      this.string_material = new THREE.LineBasicMaterial(material_parameters);
      this.string_object = new THREE.Line(this.string_geometry, this.string_material);
      this.string_object.useQuaternion = true;
      this.scene.add(this.string_object);
      this.update_scene();
      this.axis_object = new THREE.Object3D();
      this.axis_object.add(new THREE.ArrowHelper(new THREE.Vector3(1, 0, 0), new THREE.Vector3(), 1, 0xff0000));
      this.axis_object.add(new THREE.ArrowHelper(new THREE.Vector3(0, 1, 0), new THREE.Vector3(), 1, 0x00ff00));
      this.axis_object.add(new THREE.ArrowHelper(new THREE.Vector3(0, 0, 1), new THREE.Vector3(), 1, 0x0000ff));
      this.axis_object.scale = new THREE.Vector3(0.15, 0.15, 0.15);
      this.axis_object.position = new THREE.Vector3(0.2 - 1, 0.2 - this.viewport_height / this.viewport_width, 0);
      this.axis_object.useQuaternion = true;
      this.overlay_scene.add(this.axis_object);
      this.camera = new THREE.PerspectiveCamera(75, this.viewport_width / this.viewport_height, 0.1, 1000);
      this.camera.position = new THREE.Vector3(0, 0, 2);
      this.camera.up = new THREE.Vector3(0, 1, 0);
      this.camera.lookAt(new THREE.Vector3());
      this.overlay_camera = new THREE.OrthographicCamera(-1, 1, this.viewport_height / this.viewport_width, -this.viewport_height / this.viewport_width);
      this.overlay_camera.position = new THREE.Vector3(0, 0, 10);
      this.overlay_camera.up = new THREE.Vector3(0, 1, 0);
      this.overlay_camera.lookAt(new THREE.Vector3());
      this.vertical_rotation = 0;
      this.horizontal_rotation = 0;
      this.update_camera();
      return this.setup_rotation_control();
    };

    StringAnimation.prototype.setup_rotation_control = function() {
      var mouse_move_listener, prev_mouse_position,
        _this = this;

      prev_mouse_position = {};
      mouse_move_listener = function(event) {
        var mouse_difference, mouse_position;

        mouse_position = {
          x: event.x,
          y: event.y
        };
        mouse_difference = {
          x: mouse_position.x - prev_mouse_position.x,
          y: mouse_position.y - prev_mouse_position.y
        };
        prev_mouse_position = mouse_position;
        _this.vertical_rotation += 4 * Math.PI * mouse_difference.x / _this.viewport_width;
        _this.horizontal_rotation += 4 * Math.PI * mouse_difference.y / _this.viewport_height;
        _this.horizontal_rotation = Math.max(_this.horizontal_rotation, -Math.PI / 2);
        _this.horizontal_rotation = Math.min(_this.horizontal_rotation, Math.PI / 2);
        return _this.update_camera();
      };
      this.display_container.addEventListener("mousedown", function(event) {
        prev_mouse_position = {
          x: event.x,
          y: event.y
        };
        return _this.display_container.addEventListener("mousemove", mouse_move_listener);
      });
      this.display_container.addEventListener("mouseup", function() {
        return _this.display_container.removeEventListener("mousemove", mouse_move_listener);
      });
      return this.display_container.addEventListener("mouseout", function() {
        return _this.display_container.removeEventListener("mousemove", mouse_move_listener);
      });
    };

    StringAnimation.prototype.update_camera = function() {
      var rotation;

      rotation = new THREE.Quaternion();
      rotation.setFromEuler(new THREE.Vector3(this.horizontal_rotation, 0, this.vertical_rotation));
      this.axis_object.quaternion = rotation;
      return this.string_object.quaternion = rotation;
    };

    StringAnimation.prototype.main_loop = function() {
      var _this = this;

      window.requestAnimationFrame(function() {
        return _this.main_loop();
      });
      this.animate_frame(Math.min(this.clock.getDelta(), 0.05));
      this.update_scene();
      this.renderer.clear(true, true, false);
      this.renderer.render(this.scene, this.camera);
      return this.renderer.render(this.overlay_scene, this.overlay_camera);
    };

    StringAnimation.prototype.update_scene = function() {
      this.string_geometry.vertices = this.string_vertices;
      return this.string_geometry.verticesNeedUpdate = true;
    };

    StringAnimation.prototype.animate_frame = function(dt) {
      var i;

      this.animation_time += dt;
      return this.string_vertices = (function() {
        var _i, _ref2, _results;

        _results = [];
        for (i = _i = 0, _ref2 = this.string_segments; 0 <= _ref2 ? _i <= _ref2 : _i >= _ref2; i = 0 <= _ref2 ? ++_i : --_i) {
          _results.push(this.string_coordinates(this.animation_time, i / this.string_segments));
        }
        return _results;
      }).call(this);
    };

    StringAnimation.prototype.string_coordinates = function(t, sigma) {
      var coords;

      coords = this.string.coordinates_at_global_time(t, sigma);
      return (function(func, args, ctor) {
        ctor.prototype = func.prototype;
        var child = new ctor, result = func.apply(child, args);
        return Object(result) === result ? result : child;
      })(THREE.Vector3, coords, function(){});
    };

    return StringAnimation;

  })();

}).call(this);
