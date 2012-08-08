// Generated by CoffeeScript 1.3.3
(function() {
  var w,
    __slice = [].slice,
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  w = window;

  w.ck = CoffeeKup;

  w.wait = function(someTime, thenDo) {
    return setTimeout(thenDo, someTime);
  };

  w.doEvery = function(someTime, action) {
    return setInterval(action, someTime);
  };

  Backbone.Model.prototype.io = Backbone.Collection.prototype.io = Backbone.View.prototype.io = window.sock;

  Backbone.Model.prototype.sync = Backbone.Collection.prototype.sync = function(method, model, options, cb) {
    console.log('emitting: ', 'sync', this.syncName, method, model, options);
    return this.io.emit('sync', this.syncName, {
      method: method,
      model: model,
      options: options
    }, function(err, resp) {
      if (err) {
        return options.error(err);
      } else {
        return options.success(resp);
      }
    });
  };

  Backbone.View.prototype.open = function(cont) {
    if (cont == null) {
      cont = 'body';
    }
    this.$el.appendTo(cont);
    this.trigger('open', cont);
    this.isOpen = true;
    return this;
  };

  Backbone.View.prototype.render = function() {
    var _ref, _ref1;
    this.$el.html(ck.render(this.template, (_ref = (_ref1 = this.model) != null ? _ref1 : this.collection) != null ? _ref : this));
    return this;
  };

  Backbone.Router.prototype.extendRoutesWith = function(xtraRoutes) {
    var name, route, _results;
    _results = [];
    for (name in xtraRoutes) {
      route = xtraRoutes[name];
      if (_.isFunction(route)) {
        _results.push(this.route(name, name, route));
      } else {
        _results.push(this.route(name, route));
      }
    }
    return _results;
  };

  window.module = function(target, name, block) {
    var item, top, _i, _len, _ref, _ref1;
    if (arguments.length < 3) {
      _ref = [(typeof exports !== 'undefined' ? exports : window)].concat(__slice.call(arguments)), target = _ref[0], name = _ref[1], block = _ref[2];
    }
    top = target;
    _ref1 = name.split('.');
    for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
      item = _ref1[_i];
      target = target[item] || (target[item] = {});
    }
    return block(target, top);
  };

  (function($) {
    return $.fn.center = function() {
      this.css("position", "absolute");
      this.css("top", Math.max(0, (($(window).height() - this.outerHeight()) / 2) + $(window).scrollTop()) + "px");
      this.css("left", Math.max(0, (($(window).width() - this.outerWidth()) / 2) + $(window).scrollLeft()) + "px");
      return this;
    };
  })(jQuery);

  (function($) {
    return $.fn.slider = function(method) {
      var _this = this;
      this.methods = {
        init: function(options) {
          var groove, handle, root, _ref, _ref1,
            _this = this;
          if (options == null) {
            options = {};
          }
          if ((_ref = options.min) == null) {
            options.min = 0;
          }
          if ((_ref1 = options.max) == null) {
            options.max = 100;
          }
          handle = $('<div/>').addClass('slider-handle');
          groove = $('<div/>').addClass('slider-groove');
          root = $(this).addClass('slider-cont');
          handle.appendTo(groove);
          groove.appendTo(root);
          /*
                  handle.draggable {
                    containment: groove
                    axis: 'x'
                  }
          */

          root.on('mousedown', function(e) {
            _this.setHandleX(e.offsetX);
            return _this.data('dragging', true);
          });
          root.on('mouseover', function(e) {
            return _this.data('dragging', false);
          });
          return root.on('mousemove', function(e) {
            return _this.setHandleX(e.offsetX);
          });
        },
        setHandleX: function(x) {
          return handle.css('left', x - (handle.width() * 0.5));
        },
        update: function() {
          var newpx;
          console.log('move:', newpx = (this.data('v') - this.options.min) / (this.options.max - this.options.min));
          $(this).find('.slider-handle').css('left', newpx);
          return this;
        },
        val: function(v) {
          console.log(this.data('v'), v);
          if (v != null) {
            this.data('v', v);
            this.update;
            return this;
          } else {
            return this.data('v');
          }
        }
      };
      if (this.methods[method]) {
        return this.methods[method].apply(this, Array.prototype.slice.call(arguments, 1));
      } else if (typeof method === "object" || !this.method) {
        return this.methods.init.apply(this, arguments);
      } else {
        return $.error("Method " + this.method + " does not exist");
      }
    };
  })(jQuery);

  (function($) {
    /*
      # jQuery plugin for a two-click confirm button
    
      # inner content with class of 'state-initial' shows first
      # content with 'state-confirm' shows to confirm the click
      #
      # if options.initialText and options.confirmText are present,
      # button text is replaced instead
      #
      # triggers 'confirm' event on second click
      #
      # clicking outside the button cancels and takes to initial state
      #
      # call: $(el).confirmBtn({ initialText: ?, confirmState: ? })
    */
    return $.fn.confirmBtn = function(options) {
      var init,
        _this = this;
      if (options == null) {
        options = {};
      }
      init = function() {
        _this.confirmState = false;
        if ((options != null ? options.initialText : void 0) != null) {
          _this.text(options.initialText);
        } else {
          _this.find('.state-confirm').hide();
          _this.find('.state-initial').show();
        }
        return $('body').off('click.confirm-btn');
      };
      init();
      return this.click(function(e) {
        e.preventDefault();
        e.stopPropagation();
        if ((options != null ? options.confirmText : void 0) != null) {
          _this.text(options.confirmText);
        } else {
          _this.find('.state-initial').toggle();
          _this.find('.state-confirm').toggle();
        }
        if (!(_this.confirmState = !_this.confirmState)) {
          _this.trigger('confirm');
          return init();
        } else {
          return $('body').on('click.confirm-btn', init);
        }
      });
    };
  })(jQuery);

  module('App.Activity', function(exports, top) {
    var Model, Time, Timer, Views, _ref;
    Timer = (function() {

      Timer.prototype.cueTimes = [];

      function Timer(options) {
        this.options = options != null ? options : {};
        _(this).extend(Backbone.Events);
        _.defaults(this.options, {
          tickBank: 0,
          cues: [],
          autostart: false,
          loop: false,
          duration: null,
          speed: 1
        });
        this.tickBank = this.options.tickBank;
        this.cues = this.options.cues;
        this.setStatus('initialized');
        if (this.options.autostart) {
          this.start();
        }
      }

      Timer.prototype.normalize = function(secs) {
        return Math.floor(secs * 10);
      };

      Timer.prototype.seek = function(secs) {
        this.tickBank = Math.floor(secs * 1000);
        this.multiTrigger('event', 'seek', {
          from: this.currentSecs(),
          to: secs
        });
        return this;
      };

      Timer.prototype.start = function(silent) {
        var _this = this;
        if (silent == null) {
          silent = false;
        }
        this.setStatus('started', silent);
        this.tickMark = Date.now();
        this.engine = doEvery(25, function() {
          var act, thisTick, _i, _len, _ref, _ref1;
          _this.tickBank -= (_this.tickMark - (_this.tickMark = Date.now())) * _this.options.speed;
          _this.multiTrigger('event', 'tick');
          if (_ref = (thisTick = _this.normalize(_this.tickBank / 1000)), __indexOf.call(_this.cueTimes, _ref) >= 0) {
            _this.multiTrigger('event', 'cue', {
              comment: _this.comment
            });
            _ref1 = _this.cues;
            for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
              act = _ref1[_i];
              if (Math.floor(act.at * 10) === thisTick) {
                act.fn();
              }
            }
          }
          if (_this.options.duration && thisTick === _this.normalize(_this.options.duration)) {
            _this.multiTrigger('event', 'ended');
            if (_this.options.loop) {
              return _this.restart();
            } else {
              return _this.stop();
            }
          }
        });
        return this;
      };

      Timer.prototype.pause = function(silent) {
        if (silent == null) {
          silent = false;
        }
        clearTimeout(this.engine);
        this.setStatus('paused', silent);
        return this;
      };

      Timer.prototype.togglePlay = function(silent) {
        if (silent == null) {
          silent = false;
        }
        if (this.status === 'started') {
          this.pause();
        } else {
          this.start();
        }
        return this;
      };

      Timer.prototype.stop = function(silent) {
        if (silent == null) {
          silent = false;
        }
        this.pause(true);
        this.tickBank = 0;
        this.setStatus('stopped', silent);
        return this;
      };

      Timer.prototype.restart = function(silent) {
        if (silent == null) {
          silent = false;
        }
        this.multiTrigger('event', 'restarted');
        this.pause(true).stop(true).start();
        return this;
      };

      Timer.prototype.currentSecs = function() {
        return this.normalize(this.tickBank / 1000) / 10;
      };

      Timer.prototype.currentTimeObj = function() {
        var hrs, mins, secs, tenths, timeObj, totalSecs;
        totalSecs = this.currentSecs();
        hrs = Math.floor(totalSecs / 3600);
        mins = Math.floor((totalSecs - (3600 * hrs)) / 60);
        secs = Math.floor(totalSecs - (hrs * 3600) - (mins * 60));
        tenths = Math.floor(10 * (totalSecs - secs));
        return timeObj = {
          hrs: hrs,
          mins: mins,
          secs: secs,
          tenths: tenths
        };
      };

      Timer.prototype.setSpeed = function(speed) {
        return this.options.speed = speed;
      };

      Timer.prototype.addCues = function(newCues) {
        var cue, _i, _len;
        if (!_.isArray(newCues)) {
          newCues = [newCues];
        }
        for (_i = 0, _len = newCues.length; _i < _len; _i++) {
          cue = newCues[_i];
          cue.fn = _.debounce(cue.fn, 500, true);
          this.cues.push(cue);
          this.cueTimes.push(this.normalize(cue.at));
        }
        return this;
      };

      Timer.prototype.setStatus = function(status, silent) {
        this.status = status;
        if (silent == null) {
          silent = false;
        }
        if (!silent) {
          return this.multiTrigger('status', this.status);
        }
      };

      Timer.prototype.multiTrigger = function(type, name, data) {
        if (data == null) {
          data = {};
        }
        _.extend(data, {
          secs: this.currentSecs(),
          ticks: this.tickBank,
          type: type,
          name: name
        });
        this.trigger(name, _.extend(data, {
          secs: this.currentSecs(),
          ticks: this.tickBank,
          type: type
        }));
        this.trigger(type, _.extend(data, {
          secs: this.currentSecs(),
          ticks: this.tickBank,
          name: name
        }));
        return this.trigger('any', _.extend(data, {
          secs: this.currentSecs(),
          ticks: this.tickBank,
          type: type,
          name: name
        }));
      };

      return Timer;

    })();
    Time = (function() {

      function Time(totalSecs) {
        this.totalSecs = totalSecs;
        this.intSecs = Math.floor(this.totalSecs);
      }

      Time.prototype.getSecs = function() {
        var _ref;
        return (_ref = this.secs) != null ? _ref : this.secs = this.intSecs % 60;
      };

      Time.prototype.getMins = function() {
        var _ref;
        return (_ref = this.mins) != null ? _ref : this.mins = Math.floor((this.intSecs % 3600) / 60);
      };

      Time.prototype.getHrs = function() {
        return this.hrs || (this.hrs = Math.floor(this.intSecs / 3600));
      };

      Time.prototype.getTenths = function() {
        var _ref;
        return (_ref = this.tenths) != null ? _ref : this.tenths = Math.floor(10 * (this.totalSecs - this.intSecs));
      };

      Time.prototype.getSecStr = function() {
        var s;
        return ((s = this.getSecs()) < 10 ? "0" : "") + s;
      };

      Time.prototype.getMinStr = function() {
        var m;
        return ((m = this.getMins()) < 10 ? "0" : "") + m;
      };

      Time.prototype.getHrStr = function() {
        var h;
        return ((h = this.getHrs()) < 10 ? "0" : "") + h;
      };

      Time.prototype.setSecs = function(totalSecs) {
        this.totalSecs = totalSecs;
        this.intSecs = Math.floor(this.totalSecs);
        this.hrs = this.mins = this.secs = this.tenths = null;
        return this;
      };

      Time.prototype.getTimeStr = function() {
        return "" + (this.getHrs() ? this.getHrStr() + ":" : "") + (this.getMinStr()) + ":" + (this.getSecStr()) + "." + (this.getTenths());
      };

      return Time;

    })();
    exports.Time = Time;
    Model = (function(_super) {

      __extends(Model, _super);

      function Model() {
        return Model.__super__.constructor.apply(this, arguments);
      }

      Model.prototype.initialize = function() {
        this.events = new App.Activity.Event.Collection(this.get('events'));
        this.events.duration = this.get('duration');
        return this.timer = new Timer({
          duration: this.get('duration')
        });
      };

      return Model;

    })(Backbone.Model);
    exports.Views = Views = {};
    Views.Timeline = (function(_super) {

      __extends(Timeline, _super);

      function Timeline() {
        return Timeline.__super__.constructor.apply(this, arguments);
      }

      Timeline.prototype.tagName = 'div';

      Timeline.prototype.className = 'timeline';

      Timeline.prototype.initialize = function() {
        var _this = this;
        this.pixelScaleFactor = $(window).width() * 0.94 / this.model.get('duration');
        this.on('open', function() {
          _this.zoomControl.on('change', function(newZoomLevel) {
            console.log(newZoomLevel);
            _this.scaleTime(newZoomLevel);
            return _this.moveCursorToTime('timer', _this.timer.model.currentSecs());
          });
          return _this.scaleTime(1);
        });
        $(window).resize(function() {
          _this.pixelScaleFactor = $(window).width() * 0.94 / _this.model.get('duration');
          return _this.render();
        });
        this.timer = new Views.Timer({
          model: this.model.timer
        });
        this.zoomControl = new UI.Slider({
          min: 1,
          max: 4
        });
        this.model.timer.on('event', function(data) {
          var s, t, _ref;
          if ((_ref = data.name) === 'seek' || _ref === 'tick') {
            _this.moveCursorToTime('timer', s = _this.model.timer.currentSecs());
            t = new Time(s);
            return _this.$(".cursor-mark.active .time-info").text(t.getTimeStr());
          }
        });
        return this.model.timer.on('status', function(data) {
          if (data.name === 'started') {
            return _this.$('.timer-mark').addClass('active');
          } else if (data.name === 'stopped') {
            _this.$('.timer-mark').removeClass('active');
            return _this.moveCursorToTime('timer', _this.model.timer.currentSecs());
          }
        });
      };

      Timeline.prototype.events = {
        'mousedown .tick-marks': function(e) {
          var extra, target, x;
          target = $(e.target);
          extra = $(e.target).position().left;
          x = (target.hasClass('lbl') ? 0 : e.offsetX) + extra;
          if (this.userDragging) {
            this.model.timer.seek(this.toSecs(x));
          }
          this.userDragging = true;
          return this.model.timer.seek(Math.round(this.toSecs(x)));
        },
        'mouseup .tick-marks': function(e) {
          this.userDragging = false;
          return this.$('.user-mark').show();
        },
        'mousemove .tick-marks': function(e) {
          var extra, target, x;
          target = $(e.target);
          extra = $(e.target).position().left;
          x = (target.hasClass('lbl') ? 0 : e.offsetX) + extra;
          if (this.userDragging) {
            this.model.timer.seek(this.toSecs(x));
          }
          return this.moveCursorToTime('user', Math.round(this.toSecs(x)));
        },
        'mouseover .tick-marks': function(e) {
          return this.$('.user-mark').show();
        },
        'mouseout .tick-marks': function(e) {
          return this.$('.user-mark').hide();
        }
      };

      Timeline.prototype.moveCursorTo = function(type, x) {
        var t;
        if (type == null) {
          type = '';
        }
        this.$(".cursor-mark" + (type ? '.' + type + '-mark' : '')).css('left', x);
        t = new Time(this.toSecs(x));
        this.$(".user-mark .time-info").text(t.getTimeStr());
        return this;
      };

      Timeline.prototype.moveCursorToTime = function(type, secs) {
        var pixels;
        if (type == null) {
          type = '';
        }
        pixels = this.toPixels(secs);
        this.moveCursorTo(type, pixels);
        return this;
      };

      Timeline.prototype.toPixels = function(secs) {
        return secs * $('.time-cont').width() / this.model.get('duration');
      };

      Timeline.prototype.toSecs = function(pixels) {
        return pixels * this.model.get('duration') / this.$('.time-cont').width();
      };

      Timeline.prototype.scaleTime = function(zoomLevel) {
        var i, m, s, val, _i, _len, _ref;
        this.zoomLevel = zoomLevel;
        console.log('scaleTime ', this.zoomLevel, this.pixelScaleFactor);
        val = this.zoomLevel * this.pixelScaleFactor;
        this.$('.time-cont').width(val * this.model.get('duration'));
        _ref = this.$('.mark,.lbl');
        for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
          m = _ref[i];
          s = $(m).data('sec');
          $(m).css('left', "" + (Math.floor(val * s)) + "px");
        }
        this.moveCursorToTime(this.timer.model.currentSecs());
        return this.addEvents();
      };

      Timeline.prototype.template = function() {
        div({
          "class": 'time-window'
        }, function() {
          return div({
            "class": 'time-cont'
          }, function() {
            div({
              "class": 'time'
            }, function() {});
            div({
              "class": 'cursor-mark user-mark'
            }, function() {
              return div({
                "class": 'time-info'
              }, 'xx:xx:xx');
            });
            div({
              "class": 'cursor-mark timer-mark'
            }, function() {
              return div({
                "class": 'time-info'
              }, 'xx:xx:xx');
            });
            return div({
              "class": 'tick-marks'
            }, function() {
              var markLbl, sec, type, _i, _ref, _results;
              _results = [];
              for (sec = _i = 0, _ref = Math.floor(this.model.get('duration')); 0 <= _ref ? _i <= _ref : _i >= _ref; sec = 0 <= _ref ? ++_i : --_i) {
                type = sec % 60 === 0 ? 'minute' : sec % 30 === 0 ? 'half-minute' : sec % 15 === 0 ? 'quarter-minute' : sec % 5 === 0 ? 'five-second' : 'second';
                div({
                  "class": "" + type + "-mark mark",
                  'data-sec': "" + sec
                });
                markLbl = type === 'half-minute' || type === 'quarter-minute' ? (sec % 60) + 's' : (sec / 60) + 'm';
                if (type === 'half-minute' || type === 'quarter-minute' || type === 'minute') {
                  _results.push(span({
                    "class": "" + type + "-mark-lbl lbl",
                    'data-sec': "" + sec
                  }, "" + markLbl));
                } else {
                  _results.push(void 0);
                }
              }
              return _results;
            });
          });
        });
        div({
          "class": 'timer-cont'
        }, function() {});
        div({
          "class": 'time-scroll-cont'
        });
        return div({
          "class": 'scale-slider'
        });
      };

      Timeline.prototype.addEvent = function(ev) {
        var _ref;
        if ((_ref = ev.view) != null) {
          _ref.remove();
        }
        ev.view = new App.Activity.Event.Views.Event({
          model: ev
        });
        return ev.view.renderIn(this.$('.time'));
      };

      Timeline.prototype.render = function() {
        this.$el.html(ck.render(this.template, this));
        this.timer.render().open(this.$('.timer-cont'));
        this.zoomControl.render().open(this.$('.scale-slider'));
        return this;
      };

      Timeline.prototype.addEvents = function() {
        var ev, _i, _len, _ref;
        _ref = this.model.events.models;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          ev = _ref[_i];
          this.addEvent(ev);
        }
        return this;
      };

      return Timeline;

    })(Backbone.View);
    Views.Timer = (function(_super) {

      __extends(Timer, _super);

      function Timer() {
        return Timer.__super__.constructor.apply(this, arguments);
      }

      Timer.prototype.tagName = 'div';

      Timer.prototype.className = 'timer';

      Timer.prototype.initialize = function() {
        var _this = this;
        this.model.on('tick', function() {
          return _this.renderClock();
        });
        this.model.on('seek', function() {
          return _this.renderClock();
        });
        return this.model.on('status', function(event) {
          switch (event.name) {
            case "started":
              _this.$('.toggle-play').removeClass('btn-success');
              _this.$('.toggle-play i').removeClass('icon-play').addClass('icon-pause');
              return _this.$('.stop').removeClass('disabled');
            case "paused":
            case "stopped":
              _this.$('.toggle-play').addClass('btn-success');
              return _this.$('.toggle-play i').removeClass('icon-pause').addClass('icon-play');
            case "stopped":
              _this.$('.stop').addClass('disabled');
              return _this.renderClock();
          }
        });
      };

      Timer.prototype.events = {
        'click .toggle-play': function() {
          return this.model.togglePlay();
        },
        'click .stop': function() {
          return this.model.stop();
        },
        'click .speed-control a': function(e) {
          this.$('.speed-label').text($(e.currentTarget).text() + ' ');
          return this.model.setSpeed($(e.currentTarget).data('value'));
        }
      };

      Timer.prototype.clockTemplate = function() {
        var time;
        time = this.currentTimeObj();
        span({
          "class": 'mins digit'
        }, "" + time.mins);
        text(" : ");
        span({
          "class": 'secs digit'
        }, "" + time.secs);
        text(" . ");
        return span({
          "class": 'tenths digit'
        }, "" + time.tenths);
      };

      Timer.prototype.template = function() {
        div({
          "class": 'clock span4'
        }, function() {});
        return div({
          "class": 'btn-group span4'
        }, function() {
          button({
            "class": 'btn btn-success toggle-play'
          }, function() {
            return i({
              "class": 'icon-play'
            });
          });
          button({
            "class": 'btn btn-inverse stop'
          }, function() {
            return i({
              "class": 'icon-stop'
            });
          });
          a({
            "class": 'btn dropdown-toggle btn-inverse',
            'data-toggle': 'dropdown',
            href: '#'
          }, function() {
            span({
              "class": 'speed-label'
            }, '1x ');
            return span({
              "class": 'caret'
            });
          });
          return ul({
            "class": 'dropdown-menu speed-control'
          }, function() {
            li(function() {
              return a({
                'data-value': '0.25'
              }, '&frac14;x');
            });
            li(function() {
              return a({
                'data-value': '0.5'
              }, '&frac12;x');
            });
            li(function() {
              return a({
                'data-value': '0.75'
              }, '&frac34;x');
            });
            li(function() {
              return a({
                'data-value': '1'
              }, '1x');
            });
            li(function() {
              return a({
                'data-value': '1.5'
              }, '1&frac12;x');
            });
            return li(function() {
              return a({
                'data-value': '2'
              }, '2x');
            });
          });
        });
      };

      Timer.prototype.renderClock = function() {
        return this.$('.clock').html(ck.render(this.clockTemplate, this.model));
      };

      Timer.prototype.render = function() {
        this.$el.html(ck.render(this.template, this.model));
        this.renderClock();
        return this;
      };

      return Timer;

    })(Backbone.View);
    return _ref = [Timer, Model], exports.Timer = _ref[0], exports.Model = _ref[1], _ref;
  });

  module('App.Activity.Event', function(exports, top) {
    var Collection, Model, Views, _ref;
    Model = (function(_super) {

      __extends(Model, _super);

      function Model() {
        return Model.__super__.constructor.apply(this, arguments);
      }

      return Model;

    })(Backbone.Model);
    Collection = (function(_super) {

      __extends(Collection, _super);

      function Collection() {
        return Collection.__super__.constructor.apply(this, arguments);
      }

      Collection.prototype.model = Model;

      Collection.prototype.initialize = function() {
        var _ref;
        return (_ref = this.duration) != null ? _ref : this.duration = 60;
      };

      return Collection;

    })(Backbone.Collection);
    exports.Views = Views = {};
    Views.Event = (function(_super) {

      __extends(Event, _super);

      function Event() {
        return Event.__super__.constructor.apply(this, arguments);
      }

      Event.prototype.tagName = 'div';

      Event.prototype.className = 'event';

      Event.prototype.renderIn = function(parent) {
        var style;
        console.log(parent.width());
        style = {
          width: this.model.get('duration') * $(parent).width() / this.model.collection.duration,
          left: this.model.get('start') * $(parent).width() / this.model.collection.duration
        };
        this.$el.css(style);
        this.$el.appendTo(parent);
        return this;
      };

      return Event;

    })(Backbone.View);
    return _ref = [Model, Collection], exports.Model = _ref[0], exports.Collection = _ref[1], _ref;
  });

  module('App.Lab', function(exports, top) {
    var Model, Views;
    Model = (function(_super) {

      __extends(Model, _super);

      function Model() {
        return Model.__super__.constructor.apply(this, arguments);
      }

      return Model;

    })(Backbone.Model);
    exports.Views = Views = {};
    return Views.Main = (function(_super) {

      __extends(Main, _super);

      function Main() {
        return Main.__super__.constructor.apply(this, arguments);
      }

      Main.prototype.initialize = function() {
        this.model = new Model;
        return this.media = new App.Media.Views.Player;
      };

      Main.prototype.tagName = 'div';

      Main.prototype.className = 'lab';

      Main.prototype.template = function() {
        div({
          "class": 'media-cont'
        }, function() {});
        return div({
          "class": 'message-cont'
        }, function() {});
      };

      return Main;

    })(Backbone.View);
  });

  module('App.Media', function(exports, top) {
    var Model, Views, _ref;
    Model = (function(_super) {

      __extends(Model, _super);

      function Model() {
        return Model.__super__.constructor.apply(this, arguments);
      }

      return Model;

    })(Backbone.Model);
    exports.Views = Views = {};
    Views.Player = (function(_super) {

      __extends(Player, _super);

      function Player() {
        return Player.__super__.constructor.apply(this, arguments);
      }

      Player.prototype.tagName = 'div';

      Player.prototype.className = 'media-player';

      Player.prototype.template = function() {
        return video(function() {
          return source({
            src: ''
          });
        });
      };

      return Player;

    })(Backbone.Model);
    return _ref = [Model], exports.Model = _ref[0], _ref;
  });

  module('UI', function(exports, top) {
    var ConfirmDelete, Slider, Tags, _ref;
    Slider = (function(_super) {

      __extends(Slider, _super);

      function Slider() {
        return Slider.__super__.constructor.apply(this, arguments);
      }

      Slider.prototype.tagName = 'div';

      Slider.prototype.className = 'slider-cont';

      Slider.prototype.initialize = function() {
        return _.defaults(this.options, {
          min: 0,
          max: 100,
          handleWidthPerc: 0
        });
      };

      Slider.prototype.template = function() {
        return div({
          "class": 'slider-groove'
        }, function() {
          return div({
            "class": 'slider-handle'
          });
        });
      };

      Slider.prototype.render = function() {
        this.$el.html(ck.render(this.template));
        this.on('open', function() {
          this.groove = this.$('.slider-groove');
          this.handle = this.$('.slider-handle');
          return this.setHandleWidthPerc(this.options.handleWidthPerc * this.grooveW() / 100);
        });
        return this;
      };

      Slider.prototype.events = {
        'mousedown': 'startDrag',
        'mouseup': 'stopDrag',
        'mousemove': 'drag'
      };

      Slider.prototype.handleW = function() {
        return this.handle.width();
      };

      Slider.prototype.handleX = function() {
        return this.handle.position().left;
      };

      Slider.prototype.getVal = function() {
        return this.options.min + (this.handleX() / this.grooveW()) * (this.options.max - this.options.min);
      };

      Slider.prototype.setVal = function(v) {
        this.setSliderX((v - this.options.min) / (this.options.max - this.options.min) * this.grooveW());
        return this;
      };

      Slider.prototype.grooveW = function() {
        return this.groove.width() - this.handleW();
      };

      Slider.prototype.setHandleWidthPerc = function(perc) {
        return this.handle.width((perc * this.grooveW() / 100) || 8);
      };

      Slider.prototype.setSliderX = function(x) {
        x = x - (this.handleW() / 2);
        x = x < 0 ? 0 : x > this.grooveW() ? this.grooveW() : x;
        this.$('.slider-handle').css('left', x);
        this.trigger('change', this.getVal());
        return this;
      };

      Slider.prototype.startDrag = function(e) {
        var newX, targetOffsetX;
        targetOffsetX = $(e.target).hasClass('slider-handle') ? this.handleX() : 0;
        newX = e.offsetX + targetOffsetX;
        this.setSliderX(newX);
        this.dragging = true;
        return this;
      };

      Slider.prototype.stopDrag = function(e) {
        this.dragging = false;
        return this;
      };

      Slider.prototype.drag = function(e) {
        var newX, targetOffsetX;
        targetOffsetX = $(e.target).hasClass('slider-handle') ? this.handleX() : 0;
        newX = e.offsetX + targetOffsetX;
        if (this.dragging) {
          this.setSliderX(newX);
        }
        return this;
      };

      return Slider;

    })(Backbone.View);
    ConfirmDelete = (function(_super) {

      __extends(ConfirmDelete, _super);

      function ConfirmDelete() {
        return ConfirmDelete.__super__.constructor.apply(this, arguments);
      }

      ConfirmDelete.prototype.tagName = 'div';

      ConfirmDelete.prototype.className = 'modal';

      ConfirmDelete.prototype.events = {
        'click .cancel': function() {
          return this.remove();
        },
        'click .delete': function() {
          var model, _i, _len, _ref;
          _ref = this.collection;
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            model = _ref[_i];
            model.destroy();
          }
          return this.remove();
        }
      };

      ConfirmDelete.prototype.template = function() {
        div({
          "class": 'modal-header'
        }, function() {
          return h3('Are you sure?');
        });
        div({
          "class": 'modal-body'
        }, function() {
          if (this.length > 1) {
            p("You are about to delete " + this.length + " " + (this[0].modelType(true)) + ":");
            return ul(function() {
              var model, _i, _len, _results;
              _results = [];
              for (_i = 0, _len = this.length; _i < _len; _i++) {
                model = this[_i];
                _results.push(li("" + (model.displayTitle())));
              }
              return _results;
            });
          } else {
            return p("You are about to delete: " + (this[0].displayTitle()));
          }
        });
        return div({
          "class": 'modal-footer'
        }, function() {
          button({
            "class": 'btn cancel'
          }, "No, don't do it");
          return button({
            "class": 'pull-right btn btn-danger icon-trash icon-large delete'
          }, ' DELETE PERMANENTLY');
        });
      };

      ConfirmDelete.prototype.render = function() {
        this.$el.html(ck.render(this.template, this.collection));
        return this;
      };

      return ConfirmDelete;

    })(Backbone.View);
    Tags = (function(_super) {

      __extends(Tags, _super);

      function Tags() {
        return Tags.__super__.constructor.apply(this, arguments);
      }

      Tags.prototype.tagName = 'div';

      Tags.prototype.className = 'tags-ui';

      Tags.prototype.initialize = function(tags) {
        return this.reset(tags);
      };

      Tags.prototype.template = function() {
        span({
          "class": 'tags-cont'
        }, function() {
          var tag, _i, _len, _ref, _results;
          _ref = this._tags;
          _results = [];
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            tag = _ref[_i];
            _results.push(span({
              "class": 'label'
            }));
          }
          return _results;
        });
        return input({
          type: 'text',
          "class": 'tag-input',
          placeholder: 'add a tag'
        });
      };

      Tags.prototype.events = function() {
        return {
          'change input': function() {
            return this.addtag($(e.target).val());
          }
        };
      };

      Tags.prototype.addTag = function(tag) {
        this._tags.add;
        return this.render();
      };

      Tags.prototype.getArray = function() {
        return this._tags;
      };

      Tags.prototype.getString = function() {
        return this._tags.join('|');
      };

      Tags.prototype.reset = function(tags) {
        if (_.isString(tags)) {
          this._tags = tags.split('|');
        }
        if (_.isArray(tags)) {
          return this._tags = tags;
        }
      };

      Tags.prototype.render = function() {
        this.$el.html(ck.render(this.tempate(this)));
        return this;
      };

      return Tags;

    })(Backbone.View);
    return _ref = [Slider, ConfirmDelete], exports.Slider = _ref[0], exports.ConfirmDelete = _ref[1], _ref;
  });

}).call(this);
