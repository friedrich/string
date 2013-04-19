(function() {
  "use strict";
  var AmplitudeControl, ClosedString, OpenString, String, StringAnimation, add_click_and_drag_listener, reduce, setTimeout2, _ref, _ref1,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  $(window).on("load", function() {
    var string_container, _i, _len, _ref, _results;

    _ref = $("[data-string]");
    _results = [];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      string_container = _ref[_i];
      _results.push(new StringAnimation(string_container));
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
    String.prototype.regge_slope = 1;

    String.prototype.tau_steps_per_fastest_revolution = 48;

    function String(modes) {
      var _base, _base1;

      this.modes = modes;
      (_base = this.modes)[0] || (_base[0] = []);
      (_base1 = this.modes)[1] || (_base1[1] = []);
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
          return sum1 + mode.a * mode.a + mode.b * mode.b + mode.c * mode.c + mode.d * mode.d;
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
        return sum + (mode.a * Math.sin(mode.n * vplus) - mode.b * Math.cos(mode.n * vplus) + mode.c * Math.sin(mode.n * vminus) - mode.d * Math.cos(mode.n * vminus)) / mode.n;
      });
    };

    ClosedString.prototype.y_m = function(tau, sigma) {
      var vminus, vplus;

      vplus = 2 * Math.PI * (this.c * tau + sigma);
      vminus = 2 * Math.PI * (this.c * tau - sigma);
      return this.y_m_factor * reduce(this.modes, 0, function(sum, modesi) {
        return sum + reduce(modesi, 0, function(sum1, mode1) {
          return sum1 + reduce(modesi, 0, function(sum2, mode2) {
            sum2 += ((mode1.b * mode2.a + mode1.a * mode2.b) * Math.cos((mode1.n + mode2.n) * vplus) + (mode1.b * mode2.b - mode1.a * mode2.a) * Math.sin((mode1.n + mode2.n) * vplus)) / (mode1.n + mode2.n);
            if (mode1.n !== mode2.n) {
              sum2 += ((mode1.b * mode2.a - mode1.a * mode2.b) * Math.cos((mode1.n - mode2.n) * vplus) - (mode1.b * mode2.b + mode1.a * mode2.a) * Math.sin((mode1.n - mode2.n) * vplus)) / (mode1.n - mode2.n);
            }
            sum2 += ((mode1.d * mode2.c + mode1.c * mode2.d) * Math.cos((mode1.n + mode2.n) * vminus) + (mode1.d * mode2.d - mode1.c * mode2.c) * Math.sin((mode1.n + mode2.n) * vminus)) / (mode1.n + mode2.n);
            if (mode1.n !== mode2.n) {
              sum2 += ((mode1.d * mode2.c - mode1.c * mode2.d) * Math.cos((mode1.n - mode2.n) * vminus) - (mode1.d * mode2.d + mode1.c * mode2.c) * Math.sin((mode1.n - mode2.n) * vminus)) / (mode1.n - mode2.n);
            }
            return sum2;
          });
        });
      });
    };

    return ClosedString;

  })(String);

  StringAnimation = (function() {
    StringAnimation.prototype.string_segments = 80;

    function StringAnimation(container) {
      this.container = container;
      if (!this.init_display()) {
        return;
      }
      this.load_settings() && this.save_settings();
      this.init_controls();
      this.setup_rotation_control();
      this.init_animation();
      this.main_loop();
    }

    StringAnimation.prototype.init_animation = function() {
      this.clock = new THREE.Clock();
      return this.animation_time = 0;
    };

    StringAnimation.prototype.update_string = function() {
      var modes,
        _this = this;

      modes = this.indexed_modes.map(function(indexed_modesi) {
        var mode, modesi, n;

        modesi = [];
        for (n in indexed_modesi) {
          mode = indexed_modesi[n];
          if (_this.string_open) {
            if (mode.a || mode.b) {
              modesi.push(mode);
            }
          } else {
            if (mode.a || mode.b || mode.c || mode.d) {
              modesi.push(mode);
            }
          }
        }
        return modesi;
      });
      return this.string = this.string_open ? new OpenString(modes) : new ClosedString(modes);
    };

    StringAnimation.prototype.update_site_uri = function() {
      if (window.history && history.replaceState) {
        return history.replaceState(null, "", "#" + encodeURIComponent(this.mode_control_textarea.value));
      }
    };

    StringAnimation.prototype.get_mode = function(n, i) {
      var modesi;

      return modesi = (this.indexed_modes[i - 2] || {})[n];
    };

    StringAnimation.prototype.set_mode = function(n, i, settings) {
      var mode, modesi, _base, _name;

      modesi = (_base = this.indexed_modes)[_name = i - 2] || (_base[_name] = {});
      mode = modesi[n] || (modesi[n] = {
        n: n
      });
      $.extend(mode, settings);
      mode.a || (mode.a = 0);
      mode.b || (mode.b = 0);
      mode.c || (mode.c = 0);
      return mode.d || (mode.d = 0);
    };

    StringAnimation.prototype.load_settings = function() {
      var amplitude, config_string, i, kind, match, mode_search, n, settings;

      this.indexed_modes = [];
      if (window.location.hash && window.location.hash.length > 1) {
        config_string = window.location.hash;
      } else if (window.location.search && window.location.search.length > 1) {
        config_string = window.location.search;
      }
      if (config_string) {
        mode_search = /([ab])_?(\d+)_(\d+)=([-+]?\d*\.?\d+)/g;
        while ((match = mode_search.exec(config_string))) {
          kind = match[1];
          n = parseInt(match[2]);
          i = parseInt(match[3]);
          amplitude = parseFloat(match[4]);
          settings = {};
          settings[kind] = amplitude;
          this.set_mode(n, i, settings);
        }
        this.string_open = !/closed/.test(config_string);
        return true;
      } else {
        this.string_open = true;
        this.set_mode(1, 2, {
          a: 0.5
        });
        this.set_mode(2, 2, {
          a: 0.5
        });
        return false;
      }
    };

    StringAnimation.prototype.save_settings = function() {
      var i, mode, modesi, n, settings, _i, _ref2;

      if (this.string_open) {
        settings = ["open"];
      } else {
        settings = ["closed"];
      }
      for (i = _i = 0, _ref2 = this.indexed_modes.length - 1; 0 <= _ref2 ? _i <= _ref2 : _i >= _ref2; i = 0 <= _ref2 ? ++_i : --_i) {
        modesi = this.indexed_modes[i];
        i += 2;
        for (n in modesi) {
          mode = modesi[n];
          if (mode.a) {
            settings.push("a" + n + "_" + i + "=" + mode.a.toFixed(2));
          }
          if (mode.b) {
            settings.push("b" + n + "_" + i + "=" + mode.b.toFixed(2));
          }
          if (!this.string_open) {
            if (mode.a) {
              settings.push("c" + n + "_" + i + "=" + mode.c.toFixed(2));
            }
            if (mode.b) {
              settings.push("d" + n + "_" + i + "=" + mode.d.toFixed(2));
            }
          }
        }
      }
      settings = settings.join("&");
      if (window.history && history.replaceState) {
        return history.replaceState({}, "", "?" + settings);
      } else {
        return window.location.hash = settings;
      }
    };

    StringAnimation.prototype.init_controls = function() {
      var controls_table, i, max_i, max_mode, n, table_cells, tr, _i, _j, _k, _len, _ref2, _results,
        _this = this;

      controls_table = $(this.container).find("table[data-string-modes-table]")[0];
      max_i = 3;
      max_mode = 8;
      table_cells = (function() {
        _results = [];
        for (var _i = 1; 1 <= max_i ? _i <= max_i : _i >= max_i; 1 <= max_i ? _i++ : _i--){ _results.push(_i); }
        return _results;
      }).apply(this).map(function(i) {
        var _i, _results;

        return (function() {
          _results = [];
          for (var _i = 0; 0 <= max_mode ? _i <= max_mode : _i >= max_mode; 0 <= max_mode ? _i++ : _i--){ _results.push(_i); }
          return _results;
        }).apply(this).map(function(n) {
          var cell, control, mode;

          cell = document.createElement(i === 1 || n === 0 ? "th" : "td");
          if (i === 1 && n === 0) {

          } else if (i === 1) {
            cell.innerHTML = n;
          } else if (n === 0) {
            cell.className = "string-mode-coordinate-cell-" + i;
            cell.innerHTML = 'i = <span class="string-mode-coordinate">' + i + "</span>";
          } else {
            mode = _this.get_mode(n, i) || {};
            control = new AmplitudeControl({
              max: 0.5,
              size: 40,
              x: mode.a,
              y: mode.b,
              changed: function(control) {
                _this.set_mode(n, i, {
                  a: control.x,
                  b: control.y
                });
                _this.update_string();
                return _this.save_settings();
              }
            });
            cell.appendChild(control.element);
          }
          return cell;
        });
      });
      for (n = _j = 0; 0 <= max_mode ? _j <= max_mode : _j >= max_mode; n = 0 <= max_mode ? ++_j : --_j) {
        tr = document.createElement("tr");
        controls_table.appendChild(tr);
        _ref2 = [2, 1, 3];
        for (_k = 0, _len = _ref2.length; _k < _len; _k++) {
          i = _ref2[_k];
          tr.appendChild(table_cells[i - 1][n]);
        }
      }
      return this.update_string();
    };

    StringAnimation.prototype.show_not_supported = function() {
      return this.display_container.innerHTML = "<p>Not possible with your browser :-(</p>";
    };

    StringAnimation.prototype.init_display = function() {
      var e, material_parameters, renderer_parameters;

      this.display_container = $(this.container).find("[data-string-display]")[0];
      this.viewport_width = this.display_container.clientWidth;
      this.viewport_height = this.display_container.clientHeight;
      if (!(Array.prototype.reduce && window.addEventListener)) {
        this.show_not_supported();
        return false;
      }
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
        this.show_not_supported();
        return false;
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
      this.axis_object.position = new THREE.Vector3(1 - 0.2, 0.2 - this.viewport_height / this.viewport_width, 0);
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
      return true;
    };

    StringAnimation.prototype.setup_rotation_control = function() {
      var prev_mouse_position,
        _this = this;

      prev_mouse_position = null;
      return add_click_and_drag_listener(this.display_container, function(reason, mouse_position, e) {
        var mouse_difference;

        if (reason === "down") {
          prev_mouse_position = mouse_position;
          return;
        }
        if (reason === "up") {
          return;
        }
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
      });
    };

    StringAnimation.prototype.update_camera = function() {
      var rotation;

      rotation = new THREE.Quaternion();
      rotation.setFromEuler(new THREE.Vector3(this.horizontal_rotation - Math.PI / 2, 0, this.vertical_rotation + Math.PI));
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
      return new THREE.Vector3(coords[1], coords[2], coords[0]);
    };

    return StringAnimation;

  })();

  add_click_and_drag_listener = function(element, callback) {
    var get_pos, mouse_move_handler, mouse_up_handler, offset, style,
      _this = this;

    offset = null;
    style = null;
    $(element).on("mousedown", function(e) {
      var desired_cursor;

      e.preventDefault();
      $(document).on("mousemove", mouse_move_handler);
      $(document).on("mouseup", mouse_up_handler);
      offset = $(element).offset();
      if (window.getComputedStyle) {
        desired_cursor = window.getComputedStyle(element, null).cursor;
        if (!desired_cursor || desired_cursor === "auto") {
          desired_cursor = "default";
        }
        style = $('<style type="text/css">* { cursor: ' + desired_cursor + ' !important; }</style>');
      }
      if (style) {
        $("head").append(style);
      }
      callback("down", get_pos(e), e);
      return true;
    });
    get_pos = function(e) {
      return {
        x: e.pageX - offset.left,
        y: e.pageY - offset.top
      };
    };
    mouse_move_handler = function(e) {
      callback("move", get_pos(e), e);
      return true;
    };
    return mouse_up_handler = function(e) {
      $(document).off("mousemove", mouse_move_handler);
      $(document).off("mouseup", mouse_up_handler);
      if (style) {
        style.detach();
      }
      callback("up", get_pos(e), e);
      return true;
    };
  };

  AmplitudeControl = (function() {
    function AmplitudeControl(settings) {
      var _this = this;

      if (settings == null) {
        settings = {};
      }
      this.max = settings.max || 1;
      this.zero_snap_ratio = settings.zero_snap_value || 0.2;
      this.x = settings.x || 0;
      this.y = settings.y || 0;
      this.size = settings.size || 50;
      this.element = document.createElement("canvas");
      this.element.width = this.size;
      this.element.height = this.size;
      this.context = this.element.getContext("2d");
      this.gauge_radius = (this.size - 2) / 2;
      this.scaling = this.max / this.gauge_radius;
      this.update(this.x, this.y);
      add_click_and_drag_listener(this.element, function(reason, mouse_position, e) {
        var oldX, oldY, tryX, tryY;

        if (reason === "up") {
          if (settings.changed && (_this.initialX !== _this.x || _this.initialY !== _this.y)) {
            settings.changed(_this);
          }
          return;
        }
        if (reason === "down") {
          _this.initialX = _this.x;
          _this.initialY = _this.y;
        }
        oldX = _this.x;
        oldY = _this.y;
        tryX = (mouse_position.x - _this.size / 2) * _this.scaling;
        tryY = (_this.size / 2 - mouse_position.y) * _this.scaling;
        _this.update(tryX, tryY, true);
        if (settings.changing && (oldX !== _this.x || oldY !== _this.y)) {
          return settings.changing(_this);
        }
      });
    }

    AmplitudeControl.prototype.update = function(x, y, snap_to_zero) {
      this.x = x;
      this.y = y;
      if (snap_to_zero == null) {
        snap_to_zero = false;
      }
      this.r = Math.sqrt(this.x * this.x + this.y * this.y);
      if (this.r > this.max) {
        this.x *= this.max / this.r;
        this.y *= this.max / this.r;
        this.r = this.max;
      }
      if (snap_to_zero && this.r < this.max * this.zero_snap_ratio) {
        this.x = 0;
        this.y = 0;
        this.r = 0;
      }
      if (this.x || this.y || (this.phi == null)) {
        this.phi = Math.atan2(this.y, this.x);
      }
      if (this.r === 0) {
        this.context.strokeStyle = "#aaaaaa";
      } else {
        this.context.strokeStyle = "rgb(" + Math.floor(this.r / this.max * 0xff) + ", 0, 0)";
      }
      this.context.lineWidth = 1;
      this.context.clearRect(0, 0, this.size, this.size);
      this.context.beginPath();
      this.context.arc(this.size / 2, this.size / 2, this.gauge_radius, 0, 2 * Math.PI, false);
      this.context.stroke();
      this.context.strokeStyle = "black";
      this.context.lineWidth = 2;
      this.context.beginPath();
      this.context.moveTo(this.size / 2, this.size / 2);
      this.context.lineTo(this.size / 2 + this.x / this.scaling, this.size / 2 - this.y / this.scaling);
      return this.context.stroke();
    };

    return AmplitudeControl;

  })();

}).call(this);
