// Generated by CoffeeScript 1.3.3
(function() {
  var __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  module('App.Lab', function(exports, top) {
    var Collection, Model, Views, _ref;
    Model = (function(_super) {

      __extends(Model, _super);

      function Model() {
        return Model.__super__.constructor.apply(this, arguments);
      }

      Model.prototype.syncName = 'lab';

      Model.prototype.idAttribute = '_id';

      Model.prototype.initialize = function() {};

      Model.prototype.fromDB = function(data) {
        var method, model, options;
        console.log('fromDB: ', data);
        method = data.method, model = data.model, options = data.options;
        switch (method) {
          case 'update:state':
            console.log('update:state recvd:', data);
            return this.set(model);
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
    return Views.Main = (function(_super) {

      __extends(Main, _super);

      function Main() {
        return Main.__super__.constructor.apply(this, arguments);
      }

      Main.prototype.tagName = 'div';

      Main.prototype.className = 'lab-view container';

      Main.prototype.initialize = function() {
        var _this = this;
        return this.model.on('change', function() {
          return _this.render();
        });
      };

      Main.prototype.template = function() {
        return div({
          "class": 'row-fluid'
        }, function() {
          div({
            "class": 'media-cont span6'
          }, function() {
            return p('media');
          });
          return div({
            "class": 'message-cont span6'
          }, function() {
            return "" + (this.get('whiteboard'));
          });
        });
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
                li(function() {
                  return a({
                    "class": 'brand pull-left',
                    href: '#'
                  }, function() {
                    return i({
                      "class": 'icon-bolt'
                    });
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
          console.log('service', service, 'data', data);
          switch (service) {
            case 'student':
              return _this.data.student.fromDB(data);
            case 'lab':
              if (data.method === 'join') {
                _this.data.lab.set(data.model);
                return _this.router.navigate('lab', true);
              } else {
                return _this.data.lab.fromDB(data);
              }
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
