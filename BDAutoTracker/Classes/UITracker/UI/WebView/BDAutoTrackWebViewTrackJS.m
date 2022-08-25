//
//  BDAutoTrackWebViewTrackJS.m
//  Pods-BDAutoTracker_Example
//
//  Created by bob on 2019/5/10.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDAutoTrackWebViewTrackJS.h"

NSString *bd_ui_trackJS() {
    #define __bd_track_js_func__(x) @#x
    static NSString *bdTrackJSCode = __bd_track_js_func__(
  !(function () {
    "use strict";
    function t(t, e) {
      if (!(t instanceof e))
        throw new TypeError("Cannot call a class as a function");
    }
    function e(t, e) {
      for (var n = 0; n < e.length; n++) {
        var r = e[n];
        (r.enumerable = r.enumerable || !1),
          (r.configurable = !0),
          "value" in r && (r.writable = !0),
          Object.defineProperty(t, r.key, r);
      }
    }
    function n(t, n, r) {
      return n && e(t.prototype, n), r && e(t, r), t;
    }
    function r(t, e) {
      if ("function" != typeof e && null !== e)
        throw new TypeError("Super expression must either be null or a function");
      (t.prototype = Object.create(e && e.prototype, {
        constructor: { value: t, writable: !0, configurable: !0 },
      })),
        e && a(t, e);
    }
    function i(t) {
      return (i = Object.setPrototypeOf
        ? Object.getPrototypeOf
        : function (t) {
            return t.__proto__ || Object.getPrototypeOf(t);
          })(t);
    }
    function a(t, e) {
      return (a =
        Object.setPrototypeOf ||
        function (t, e) {
          return (t.__proto__ = e), t;
        })(t, e);
    }
    function o(t, e) {
      if (e && ("object" == typeof e || "function" == typeof e)) return e;
      return (function (t) {
        if (void 0 === t)
          throw new ReferenceError(
            "this hasn't been initialised - super() hasn't been called"
          );
        return t;
      })(t);
    }
    function u(t) {
      var e = (function () {
        if ("undefined" == typeof Reflect || !Reflect.construct) return !1;
        if (Reflect.construct.sham) return !1;
        if ("function" == typeof Proxy) return !0;
        try {
          return (
            Date.prototype.toString.call(
              Reflect.construct(Date, [], function () {})
            ),
            !0
          );
        } catch (t) {
          return !1;
        }
      })();
      return function () {
        var n,
          r = i(t);
        if (e) {
          var a = i(this).constructor;
          n = Reflect.construct(r, arguments, a);
        } else n = r.apply(this, arguments);
        return o(this, n);
      };
    }
    function c(t, e, n) {
      return (c =
        "undefined" != typeof Reflect && Reflect.get
          ? Reflect.get
          : function (t, e, n) {
              var r = (function (t, e) {
                for (
                  ;
                  !Object.prototype.hasOwnProperty.call(t, e) &&
                  null !== (t = i(t));

                );
                return t;
              })(t, e);
              if (!r) return;
              var a = Object.getOwnPropertyDescriptor(r, e);
              if (a.get) return a.get.call(n);
              return a.value;
            })(t, e, n || t);
    }
    function s(t) {
      if (["LI", "TR", "DL"].includes(t.nodeName)) return !0;
      if (t.dataset && t.dataset.hasOwnProperty("teaIdx")) return !0;
      if (t.hasAttribute && t.hasAttribute("data-tea-idx")) return !0;
      return !1;
    }
    function l(t) {
      if (!t) return !1;
      if (["A", "BUTTON"].includes(t.nodeName)) return !0;
      if (t.dataset && t.dataset.hasOwnProperty("teaContainer")) return !0;
      if (t.hasAttribute && t.hasAttribute("data-tea-container")) return !0;
      return !1;
    }
    function h(t) {
      for (var e = t; e && !l(e); ) {
        if ("HTML" === e.nodeName || "BODY" === e.nodeName) return t;
        e = e.parentElement;
      }
      return e || t;
    }
    function f(t) {
      for (var e = []; null !== t.parentElement; )
        e.push(t), (t = t.parentElement);
      var n = [],
        r = [];
      return (
        e.forEach(function (t) {
          var e = (function (t) {
              if (null === t) return { str: "", index: 0 };
              var e = 0,
                n = t.parentElement;
              if (n)
                for (var r = 0; r < n.children.length && n.children[r] !== t; r++)
                  n.children[r].nodeName === t.nodeName && e++;
              return {
                str: [t.nodeName.toLowerCase(), s(t) ? "[]" : ""].join(""),
                index: e,
              };
            })(t),
            i = e.str,
            a = e.index;
          n.unshift(i), r.unshift(a);
        }),
        { element_path: "/".concat(n.join("/")), positions: r }
      );
    }
    function d(t) {
      var e = { element_path: "", positions: [], texts: [] },
        n = f(t),
        r = n.element_path,
        i = n.positions,
        a = (function (t) {
          var e = h(t),
            n = [];
          return (
            !(function t(e) {
              var r = (function (t) {
                var e = "";
                return (
                  3 === t.nodeType
                    ? (e = t.textContent.trim())
                    : (t.dataset && t.dataset.hasOwnProperty("teaTitle")) ||
                      t.hasAttribute("data-tea-title")
                    ? (e = t.getAttribute("data-tea-title"))
                    : t.hasAttribute("title")
                    ? (e = t.getAttribute("title"))
                    : "INPUT" === t.nodeName &&
                      ["button", "submit"].includes(t.getAttribute("type"))
                    ? (e = t.getAttribute("value"))
                    : "IMG" === t.nodeName &&
                      t.getAttribute("alt") &&
                      (e = t.getAttribute("alt")),
                  e.slice(0, 200)
                );
              })(e);
              if (
                (r && -1 === n.indexOf(r) && n.push(r), e.childNodes.length > 0)
              )
                for (var i = e.childNodes, a = 0; a < i.length; a++)
                  8 !== i[a].nodeType && t(i[a]);
            })(e),
            n
          );
        })(t);
      (e.element_path = r),
        (e.positions = i.map(function (t) {
          return "".concat(t);
        })),
        (e.texts = a);
      var o = h(t);
      if (
        ("A" === o.tagName && (e.href = o.getAttribute("href")),
        "IMG" === t.tagName)
      ) {
        var u = t.getAttribute("src");
        u && 0 === u.trim().indexOf("data:") && (u = ""), (e.src = u);
      }
      return (
        (e.page_title = document.title),
        (e.element_id = t.id),
        (e.element_type = t.tagName),
        e
      );
    }
    var p = (function () {
        function e(n, r) {
          var i = this;
          t(this, e),
            (this.handler = function (t) {
              var e = (t = i.getEvent(t)).target;
              if (!i.checkShouldTrackElement(e) || i.checkShouldIgnore(e)) return;
              var n = i.getPositionData(e),
                r = i.getEventData(t, n),
                a = i.getElementData(e),
                o = i.getAllData(r, a, {
                  element_width: Math.floor(n.element_width),
                  element_height: Math.floor(n.element_height),
                });
              i.report(o);
            }),
            (this.info = n),
            (this.autoTrack = r),
            this.listen();
        }
        return (
          n(e, [
            {
              key: "listen",
              value: function () {
                this.autoTrack.root.addEventListener(
                  this.info.eventType,
                  this.handler,
                  !0
                );
              },
            },
            {
              key: "_checkShouldTrackElement",
              value: function (t) {
                return (function (t) {
                  var e = window.innerHeight,
                    n = window.innerWidth;
                  if (1 !== t.nodeType) return !1;
                  if (
                    (function (t) {
                      for (var e = t.parentElement, n = !1; e; )
                        "svg" === e.tagName.toLowerCase()
                          ? ((e = null), (n = !0))
                          : (e = e.parentElement);
                      return n;
                    })(t)
                  )
                    return !1;
                  if (["HTML", "BODY"].includes(t.tagName.toUpperCase()))
                    return !1;
                  var r = t;
                  if ("none" === r.style.display) return !1;
                  if (l(r)) return !0;
                  if (
                    !(function (t) {
                      if (t.children.length > 0) {
                        var e = t.children;
                        if (
                          [].slice.call(e).some(function (t) {
                            return t.children.length > 0;
                          })
                        )
                          return !1;
                        return !0;
                      }
                      return !0;
                    })(r)
                  )
                    return !1;
                  if (r.clientHeight * r.clientWidth > 0.5 * e * n) return !1;
                  return !0;
                })(t);
              },
            },
            {
              key: "checkShouldTrackElement",
              value: function (t) {
                return !0;
              },
            },
            {
              key: "checkShouldIgnore",
              value: function (t) {
                return (function (t) {
                  for (var e = t; e && e.parentNode; ) {
                    if (e.hasAttribute("data-tea-ignore")) return !0;
                    if ("HTML" === e.nodeName || "body" === e.nodeName) return !1;
                    e = e.parentNode;
                  }
                  return !1;
                })(t);
              },
            },
            {
              key: "getEvent",
              value: function (t) {
                return t;
              },
            },
            {
              key: "getEventData",
              value: function () {
                var t =
                    arguments.length > 0 && void 0 !== arguments[0]
                      ? arguments[0]
                      : {},
                  e =
                    arguments.length > 1 && void 0 !== arguments[1]
                      ? arguments[1]
                      : {},
                  n = t.clientX,
                  r = t.clientY,
                  i = e.left,
                  a = e.top;
                return { touch_x: Math.floor(n - i), touch_y: Math.floor(r - a) };
              },
            },
            {
              key: "getElementData",
              value: function (t) {
                return d(t);
              },
            },
            {
              key: "getPositionData",
              value: function (t) {
                if (!t) return;
                var e = t.getBoundingClientRect(),
                  n = e.width,
                  r = e.height;
                return {
                  left: e.left,
                  top: e.top,
                  element_width: n,
                  element_height: r,
                };
              },
            },
            {
              key: "getAllData",
              value: function () {
                var t =
                    arguments.length > 0 && void 0 !== arguments[0]
                      ? arguments[0]
                      : {},
                  e =
                    arguments.length > 1 && void 0 !== arguments[1]
                      ? arguments[1]
                      : {},
                  n =
                    arguments.length > 2 && void 0 !== arguments[2]
                      ? arguments[2]
                      : {};
                return Object.assign(
                  Object.assign(Object.assign(Object.assign({}, t), e), n),
                  { is_html: 1, page_key: window.location.href }
                );
              },
            },
            {
              key: "report",
              value: function (t) {
                this.autoTrack.report(this.info.eventName, t);
              },
            },
            {
              key: "destroy",
              value: function () {
                this.autoTrack.root.removeEventListener(
                  this.info.eventName,
                  this.handler,
                  !0
                ),
                  (this.autoTrack = null);
              },
            },
          ]),
          e
        );
      })(),
      v = (function (e) {
        r(o, e);
        var a = u(o);
        function o(e) {
          var n;
          t(this, o),
            ((n = a.call(this, { eventName: "bav2b_page" }, e)).handler =
              function (t) {
                if (n.checkHref()) return;
                n._handler();
              }),
            (n._handler = function () {
              n.setHref();
              var t = n.getAllData();
              n.report(t);
            }),
            n._listen();
          try {
            "loading" === document.readyState
              ? document.addEventListener("DOMContentLoaded", n._handler)
              : setTimeout(n._handler);
          } catch (t) {}
          return n;
        }
        return (
          n(o, [
            { key: "listen", value: function () {} },
            {
              key: "_listen",
              value: function () {
                var t = this;
                (this._oldPushState = history.pushState),
                  (this._oldReplaceState = history.replaceState),
                  (history.pushState = function () {
                    try {
                      for (
                        var e, n = arguments.length, r = new Array(n), i = 0;
                        i < n;
                        i++
                      )
                        r[i] = arguments[i];
                      return (e = t._oldPushState).call.apply(
                        e,
                        [history].concat(r)
                      );
                    } finally {
                      t._handler();
                    }
                  }),
                  (history.replaceState = function () {
                    try {
                      for (
                        var e, n = arguments.length, r = new Array(n), i = 0;
                        i < n;
                        i++
                      )
                        r[i] = arguments[i];
                      return (e = t._oldReplaceState).call.apply(
                        e,
                        [history].concat(r)
                      );
                    } finally {
                      t._handler();
                    }
                  }),
                  window.addEventListener("hashchange", this.handler, !0),
                  window.addEventListener("popstate", this.handler, !0);
              },
            },
            {
              key: "setHref",
              value: function (t) {
                this._currentHref = t || window.location.href;
              },
            },
            {
              key: "checkHref",
              value: function () {
                return this._currentHref === window.location.href;
              },
            },
            {
              key: "getAllData",
              value: function () {
                return Object.assign(
                  Object.assign(
                    {},
                    c(i(o.prototype), "getAllData", this).call(this)
                  ),
                  {
                    is_bav: 1,
                    page_key: this._currentHref,
                    refer_page_key: document.referrer,
                    page_title: document.title,
                    page_path: this._currentHref,
                    referrer_page_path: document.referrer,
                  }
                );
              },
            },
            {
              key: "destroy",
              value: function () {
                window.removeEventListener("popstate", this.handler, !0),
                  window.removeEventListener("hashchange", this.handler, !0),
                  (history.pushState = this._oldPushState),
                  (history.replaceState = this._oldReplaceState),
                  (this._oldPushState = null),
                  (this._oldReplaceState = null),
                  (this.autoTrack = null);
              },
            },
          ]),
          o
        );
      })(p),
      g = (function (e) {
        r(o, e);
        var a = u(o);
        function o(e) {
          return (
            t(this, o),
            a.call(this, { eventType: "click", eventName: "bav2b_click" }, e)
          );
        }
        return (
          n(o, [
            {
              key: "checkShouldTrackElement",
              value: function (t) {
                return c(i(o.prototype), "_checkShouldTrackElement", this).call(
                  this,
                  t
                );
              },
            },
          ]),
          o
        );
      })(p),
      y = (function (e) {
        r(o, e);
        var a = u(o);
        function o(e) {
          var n;
          return (
            t(this, o),
            ((n = a.call(this, { eventName: "bav2b_click" }, e)).startHandler =
              function (t) {
                var e = n.autoTrack.root,
                  r = !1,
                  i = function () {
                    r = !0;
                  };
                e.addEventListener("touchmove", i, !0),
                  e.addEventListener(
                    "touchend",
                    function t(a) {
                      r || n.handler(a),
                        e.removeEventListener("touchmove", i, !0),
                        e.removeEventListener("touchend", t, !0);
                    },
                    !0
                  );
              }),
            n._listen(),
            n
          );
        }
        return (
          n(o, [
            { key: "listen", value: function () {} },
            {
              key: "_listen",
              value: function () {
                this.autoTrack.root.addEventListener(
                  "touchstart",
                  this.startHandler,
                  !0
                );
              },
            },
            {
              key: "getEvent",
              value: function (t) {
                return t.changedTouches[0];
              },
            },
            {
              key: "checkShouldTrackElement",
              value: function (t) {
                if (
                  !c(i(o.prototype), "_checkShouldTrackElement", this).call(
                    this,
                    t
                  )
                )
                  return !1;
                if (
                  "input" === t.nodeName.toLowerCase() &&
                  ["text", "password", "email", "tel", "number", "url"].includes(
                    t.type
                  )
                )
                  return !1;
                return !0;
              },
            },
            {
              key: "destroy",
              value: function () {
                this.autoTrack.root.removeEventListener(
                  "touchstart",
                  this.startHandler,
                  !0
                ),
                  (this.autoTrack = null);
              },
            },
          ]),
          o
        );
      })(p),
      m = (function () {
        function e() {
          t(this, e),
            (this.version = "1.2.1"),
            (this.options = { page: !1, touch: !1, click: !1 }),
            (this.root = document),
            (this.eventInstances = []),
            (this.started = !1);
        }
        return (
          n(
            e,
            [
              {
                key: "init",
                value: function (t, e) {
                  (this.options = Object.assign(
                    Object.assign({}, this.options),
                    t
                  )),
                    (this.reportAdapter = e);
                },
              },
              {
                key: "start",
                value: function () {
                  if (this.started) return;
                  this.started = !0;
                  var t = this.options,
                    e = t.page,
                    n = t.click,
                    r = t.touch;
                  e && this.eventInstances.push(new v(this)),
                    n && this.eventInstances.push(new g(this)),
                    r && this.eventInstances.push(new y(this));
                },
              },
              {
                key: "stop",
                value: function () {
                  (this.started = !1),
                    this.eventInstances.forEach(function (t) {
                      return t.destroy();
                    }),
                    (this.root = null);
                },
              },
              {
                key: "report",
                value: function () {
                  this.reportAdapter && this.reportAdapter.apply(this, arguments);
                },
              },
            ],
            [
              {
                key: "getInstance",
                value: function () {
                  return e.instance || (e.instance = new e()), e.instance;
                },
              },
            ]
          ),
          e
        );
      })();
    m.instance = null;
    var w, k, _;
    if ((console.log("Winter Is Coming!"), !window.TEAWebviewAutoTrack)) {
      var b = null,
        E = function (t) {
          b ||
            (b =
              window.TEANativeReport &&
              "function" == typeof window.TEANativeReport.postMessage
                ? function (t) {
                    window.TEANativeReport.postMessage(t);
                  }
                : window.TEANativeReport &&
                  "function" == typeof window.TEANativeReport
                ? function (t) {
                    window.TEANativeReport(t);
                  }
                : window.webkit &&
                  window.webkit.messageHandlers &&
                  window.webkit.messageHandlers.TEANativeReport &&
                  "function" ==
                    typeof window.webkit.messageHandlers.TEANativeReport
                      .postMessage
                ? function (t) {
                    window.webkit.messageHandlers.TEANativeReport.postMessage(t);
                  }
                : function (t) {}),
            b(t);
        },
        T =
          ((w = { page: !0, touch: !0, click: !1 }),
          (k = function () {
            for (var t = arguments.length, e = new Array(t), n = 0; n < t; n++)
              e[n] = arguments[n];
            var r = e[0],
              i = e[1],
              a = [
                { event: r, is_bav: 1, local_time_ms: +new Date(), params: i },
              ];
            console.log(a[0]), E(JSON.stringify(a));
          }),
          (_ = m.getInstance()).init(w, k),
          _);
      T.start(), (window.TEAWebviewAutoTrack = T);
    }
  })();

    );
    #undef __bd_track_js_func__

    return bdTrackJSCode;
}
