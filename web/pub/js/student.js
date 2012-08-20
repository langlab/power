// Generated by CoffeeScript 1.3.3
(function() {
  var __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  module('App.Lab', function(exports, top) {
    var Collection, Model, UIState, Views, _ref;
    UIState = (function(_super) {

      __extends(UIState, _super);

      function UIState() {
        return UIState.__super__.constructor.apply(this, arguments);
      }

      return UIState;

    })(Backbone.Model);
    Model = (function(_super) {

      __extends(Model, _super);

      function Model() {
        return Model.__super__.constructor.apply(this, arguments);
      }

      Model.prototype.syncName = 'lab';

      Model.prototype.idAttribute = '_id';

      Model.prototype.initialize = function() {
        return this.set({
          'whiteBoardA': new UIState,
          'whiteBoardB': new UIState,
          'mediaA': new UIState,
          'mediaB': new UIState,
          'recorder': new UIState
        });
      };

      Model.prototype.updateState = function(model) {
        var area, data;
        console.log('model: ', model);
        for (area in model) {
          data = model[area];
          this.get(area).set(model[area]);
        }
        console.log('triggering join');
        return this.trigger('join');
      };

      Model.prototype.fromDB = function(data) {
        var action, method, model, options, prop, val, _ref, _results;
        console.log('lab fromDB: ', data);
        method = data.method, model = data.model, options = data.options;
        switch (method) {
          case 'join':
            this.updateState(model);
            return console.log('updated');
          case 'action':
            action = model.action;
            switch (model.action) {
              case 'update':
                _results = [];
                for (prop in model) {
                  val = model[prop];
                  if (prop !== 'action') {
                    _results.push((_ref = this.get(prop)) != null ? _ref.set(val) : void 0);
                  }
                }
                return _results;
            }
        }
      };

      return Model;

    })(Backbone.Model);
    Collection = (function(_super) {

      __extends(Collection, _super);

      function Collection() {
        return Collection.__super__.constructor.apply(this, arguments);
      }

      Collection.prototype.model = Model;

      Collection.prototype.syncName = 'lab';

      return Collection;

    })(Backbone.Collection);
    _ref = [Model, Collection], exports.Model = _ref[0], exports.Collection = _ref[1];
    exports.Views = Views = {};
    Views.WhiteBoard = (function(_super) {

      __extends(WhiteBoard, _super);

      function WhiteBoard() {
        return WhiteBoard.__super__.constructor.apply(this, arguments);
      }

      WhiteBoard.prototype.tagName = 'div';

      WhiteBoard.prototype.className = 'wb-cont';

      WhiteBoard.prototype.initialize = function() {
        var _this = this;
        return this.model.on('change:html', function() {
          return _this.render();
        });
      };

      WhiteBoard.prototype.render = function() {
        this.$el.html(this.model.get('html'));
        return this;
      };

      return WhiteBoard;

    })(Backbone.View);
    Views.MediaPlayer = (function(_super) {

      __extends(MediaPlayer, _super);

      function MediaPlayer() {
        return MediaPlayer.__super__.constructor.apply(this, arguments);
      }

      MediaPlayer.prototype.tagName = 'div';

      MediaPlayer.prototype.className = 'media-cont';

      MediaPlayer.prototype.initialize = function() {
        var _this = this;
        this.model.on('change:file', function(m, file) {
          console.log('file changed');
          return _this.render();
        });
        this.model.on('change:state', function(m, state) {
          var _ref1, _ref2, _ref3, _ref4, _ref5;
          switch (state) {
            case 'playing':
              if ((_ref1 = _this.pc) != null) {
                _ref1.playbackRate(m.get('playbackRate'));
              }
              if ((_ref2 = _this.pc) != null) {
                _ref2.currentTime(m.get('currentTime'));
              }
              return (_ref3 = _this.pc) != null ? _ref3.play() : void 0;
            case 'paused':
              if ((_ref4 = _this.pc) != null) {
                _ref4.currentTime(m.get('currentTime'));
              }
              return (_ref5 = _this.pc) != null ? _ref5.pause() : void 0;
          }
        });
        this.model.on('change:currentTime', function(m, time) {
          var _ref1;
          return (_ref1 = _this.pc) != null ? _ref1.currentTime(time) : void 0;
        });
        this.model.on('change:playbackRate', function(m, rate) {
          var _ref1, _ref2;
          if ((_ref1 = _this.pc) != null) {
            _ref1.currentTime(m.get('currentTime'));
          }
          console.log('changed rate', rate);
          return (_ref2 = _this.pc) != null ? _ref2.playbackRate(rate) : void 0;
        });
        this.model.on('change:muted', function(m, muted) {
          if (muted) {
            return _this.pc.mute();
          } else {
            return _this.pc.unmute();
          }
        });
        return this.model.on('change:visible', function(m, viz) {
          return _this.$('.media').toggleClass('hid', !viz);
        });
      };

      MediaPlayer.prototype.template = function() {
        var file;
        file = this.model.get('file');
        return div({
          "class": 'media'
        }, function() {
          if (file != null) {
            switch (file.type) {
              case 'image':
                return img({
                  src: "" + file.imageUrl
                });
              case 'video':
                return video({
                  controls: 'true'
                }, function() {
                  source({
                    src: "" + file.webmUrl
                  });
                  return source({
                    src: "" + file.h264Url
                  });
                });
              case 'audio':
                return audio({
                  controls: 'true'
                }, function() {
                  return source({
                    src: "" + file.mp3Url
                  });
                });
            }
          }
        });
      };

      MediaPlayer.prototype.setPcEvents = function() {
        var type, _ref1,
          _this = this;
        type = (_ref1 = this.model.get('file')) != null ? _ref1.type : void 0;
        this.pc = Popcorn(this.$(type)[0]);
        return this.pc.on('canplay', function() {
          _this.pc.currentTime(_this.model.get('currentTime'));
          return _this.pc.playbackRate(_this.model.get('playbackRate'));
        });
      };

      MediaPlayer.prototype.render = function() {
        var type, _ref1, _ref2;
        this.$el.html(ck.render(this.template, this.options));
        this.$('.media').toggleClass('hid', !this.model.get('visible'));
        if ((_ref1 = (type = (_ref2 = this.model.get('file')) != null ? _ref2.type : void 0)) === 'video' || _ref1 === 'audio') {
          this.setPcEvents();
        }
        return this;
      };

      return MediaPlayer;

    })(Backbone.View);
    Views.Recorder = (function(_super) {

      __extends(Recorder, _super);

      function Recorder() {
        return Recorder.__super__.constructor.apply(this, arguments);
      }

      Recorder.prototype.tagName = 'div';

      Recorder.prototype.className = 'lab-recorder';

      Recorder.prototype.initialize = function() {
        var _this = this;
        this.rec = $('applet')[0];
        return this.model.on('change:state', function(m, state) {
          switch (state) {
            case 'recording':
              _this.rec.sendGongRequest('RecordMedia', 'audio');
              break;
            case 'paused-recording':
              _this.rec.sendGongRequest('PauseMedia', 'audio');
              break;
            case 'stopped-recording':
              _this.rec.sendGongRequest('StopMedia', 'audio');
              break;
            case 'playing':
              _this.rec.sendGongRequest('PlayMedia', 'audio');
              break;
            case 'paused-playing':
              _this.rec.sendGongRequest('PauseMedia', 'audio');
          }
          return _this.render();
        });
      };

      Recorder.prototype.template = function() {
        return div({
          "class": 'state'
        }, "" + (this.get('state')));
      };

      return Recorder;

    })(Backbone.View);
    return Views.Main = (function(_super) {

      __extends(Main, _super);

      function Main() {
        return Main.__super__.constructor.apply(this, arguments);
      }

      Main.prototype.tagName = 'div';

      Main.prototype.className = 'lab-view container';

      Main.prototype.initialize = function() {
        var _this = this;
        this.wbA = new Views.WhiteBoard({
          model: this.model.get('whiteBoardA')
        });
        this.wbB = new Views.WhiteBoard({
          model: this.model.get('whiteBoardB')
        });
        this.mediaA = new Views.MediaPlayer({
          model: this.model.get('mediaA')
        });
        this.mediaB = new Views.MediaPlayer({
          model: this.model.get('mediaB')
        });
        this.recorder = new Views.Recorder({
          model: this.model.get('recorder')
        });
        this.wbA.model.on('change:visible', function(m, v) {
          if (v) {
            return _this.wbA.render().open(_this.$('.wb-cont-a'));
          } else {
            return _this.wbA.remove();
          }
        });
        return this.wbB.model.on('change:visible', function(m, v) {
          if (v) {
            return _this.wbB.render().open(_this.$('.wb-cont-b'));
          } else {
            return _this.wbB.remove();
          }
        });
      };

      Main.prototype.template = function() {
        return div({
          "class": 'row-fluid'
        }, function() {
          div({
            "class": 'span6'
          }, function() {
            div({
              "class": 'media-cont-a'
            }, function() {});
            return div({
              "class": 'media-cont-b'
            }, function() {});
          });
          return div({
            "class": 'span6'
          }, function() {
            div({
              "class": 'recorder-cont'
            });
            div({
              "class": 'wb-cont-a'
            }, function() {});
            return div({
              "class": 'wb-cont-b'
            }, function() {});
          });
        });
      };

      Main.prototype.render = function() {
        Main.__super__.render.call(this);
        console.log('lab render called');
        if (this.wbA.model.get('visible')) {
          this.wbA.render().open(this.$('.wb-cont-a'));
        }
        if (this.wbB.model.get('visible')) {
          this.wbB.render().open(this.$('.wb-cont-b'));
        }
        this.mediaA.open(this.$('.media-cont-a'));
        this.mediaB.open(this.$('.media-cont-b'));
        this.recorder.render().open(this.$('.recorder-cont'));
        return this;
      };

      return Main;

    })(Backbone.View);
  });

  module('App.Student', function(exports, top) {
    var Model, Views;
    Model = (function(_super) {

      __extends(Model, _super);

      function Model() {
        return Model.__super__.constructor.apply(this, arguments);
      }

      Model.prototype.syncName = 'student';

      Model.prototype.idAttribute = '_id';

      Model.prototype.fromDB = function(data) {
        var method, model, options;
        method = data.method, model = data.model, options = data.options;
        switch (method) {
          case 'piggyBank':
            return this.set('piggyBank', model.piggyBank);
        }
      };

      return Model;

    })(Backbone.Model);
    exports.Model = [Model][0];
    exports.Views = Views = {};
    return Views.TopBar = (function(_super) {

      __extends(TopBar, _super);

      function TopBar() {
        return TopBar.__super__.constructor.apply(this, arguments);
      }

      TopBar.prototype.tagName = 'div';

      TopBar.prototype.className = 'top-bar navbar navbar-fixed-top';

      TopBar.prototype.initialize = function() {
        var _this = this;
        return this.model.on('change:piggyBank', function(m, v) {
          return _this.$('.piggyBank').text(" " + (_this.model.get('piggyBank')));
        });
      };

      TopBar.prototype.updateNav = function() {
        var rt;
        rt = Backbone.history.fragment.split('/')[0];
        this.$('ul.nav li').removeClass('active');
        this.$("ul.nav a[href=#" + rt + "]").parent('li').addClass('active');
        return this;
      };

      TopBar.prototype.template = function() {
        return div({
          "class": 'navbar-inner'
        }, function() {
          return div({
            "class": 'container'
          }, function() {
            a({
              "class": 'btn btn-navbar',
              'data-toggle': 'collapse',
              'data-target': '.nav-collapse'
            }, function() {
              span({
                "class": 'icon-beaker icon-large'
              });
              return span({
                "class": 'icon-reorder icon-large'
              });
            });
            return div({
              "class": 'nav-collapse'
            }, function() {
              ul({
                "class": 'nav'
              }, function() {
                li({
                  "class": 'user'
                }, function() {
                  return span(function() {
                    i({
                      "class": 'icon-user'
                    });
                    return text(" " + (this.get('name')) + " ");
                  });
                });
                li({
                  "class": 'divider-vertical'
                });
                li(function() {
                  return a({
                    href: '#lab'
                  }, function() {
                    i({
                      "class": 'icon-headphones'
                    });
                    return text(' Lab');
                  });
                });
                li(function() {
                  return a({
                    href: '#practice'
                  }, function() {
                    i({
                      "class": 'icon-refresh'
                    });
                    return text(' Practice');
                  });
                });
                return li(function() {
                  return a({
                    href: '#achievements'
                  }, function() {
                    i({
                      "class": 'icon-trophy'
                    });
                    return text(' Achievements');
                  });
                });
              });
              return ul({
                "class": 'nav pull-right'
              }, function() {
                li({
                  "class": 'divider-vertical'
                });
                li({
                  "class": 'heartbeats'
                }, function() {
                  return a({
                    href: '#'
                  }, function() {
                    i({
                      "class": 'icon-heart'
                    });
                    return span({
                      "class": 'piggyBank'
                    }, " " + (this.get('piggyBank')));
                  });
                });
                li({
                  "class": 'divider-vertical'
                });
                return li(function() {
                  return a({
                    href: '/studentLogout'
                  }, function() {
                    return i({
                      "class": 'icon-signout'
                    });
                  });
                });
              });
            });
          });
        });
      };

      return TopBar;

    })(Backbone.View);
  });

  module('App', function(exports, top) {
    var Model, Router;
    Model = (function() {

      function Model() {
        this.socketConnect();
        this.fromDB();
        this.data = {
          student: new App.Student.Model(top.data.session.student),
          lab: new App.Lab.Model
        };
        this.views = {
          topBar: new App.Student.Views.TopBar({
            model: this.data.student
          }),
          lab: new App.Lab.Views.Main({
            model: this.data.lab
          })
        };
        this.router = new Router(this.data, this.views);
        Backbone.history.start();
      }

      Model.prototype.fromDB = function() {
        var _this = this;
        return this.connection.on('sync', function(service, data) {
          switch (service) {
            case 'student':
              return _this.data.student.fromDB(data);
            case 'lab':
              if (data.method === 'join') {
                _this.router.navigate('lab', true);
              }
              return _this.data.lab.fromDB(data);
          }
        });
      };

      Model.prototype.socketConnect = function() {
        this.connection = window.sock = window.io.connect("https://" + data.CFG.API.HOST);
        return this.connectionView = new App.Connection.Views.Main({
          model: this.connection
        });
      };

      return Model;

    })();
    exports.Model = [Model][0];
    return Router = (function(_super) {

      __extends(Router, _super);

      function Router() {
        return Router.__super__.constructor.apply(this, arguments);
      }

      Router.prototype.initialize = function(data, views) {
        this.data = data;
        this.views = views;
        return this.showTopBar();
      };

      Router.prototype.routes = {
        '': 'home',
        'lab': 'lab'
      };

      Router.prototype.showTopBar = function() {
        return this.views.topBar.render().open();
      };

      Router.prototype.home = function() {};

      Router.prototype.lab = function() {
        this.clearViews('topBar');
        return this.views.lab.render().open();
      };

      return Router;

    })(Backbone.Router);
  });

  $(function() {
    return window.app = new App.Model;
  });

}).call(this);
