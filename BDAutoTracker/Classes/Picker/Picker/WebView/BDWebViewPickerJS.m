//
//  BDWebViewPickerJS.m
//  Pods-BDAutoTracker_Example
//
//  Created by bob on 2019/7/6.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDWebViewPickerJS.h"

NSString *bd_picker_pickerJS() {
    #define __picker_js_func__(x) @#x
    static NSString *bdPickerJSCode = __picker_js_func__(
 ! (function() {
     "use strict";

     function e(e) {
         if (["LI", "TR", "DL"].includes(e.nodeName)) return !0;
         if (e.dataset && e.dataset.hasOwnProperty("teaIdx")) return !0;
         if (e.hasAttribute && e.hasAttribute("data-tea-idx")) return !0;
         return !1
     }

     function n(n) {
         for (var t = []; null !== n.parentElement;) t.push(n), n = n.parentElement;
         var r = [],
             i = [];
         return t.forEach((function(n) {
             var t = function(n) {
                     if (null === n) return {
                         str: "",
                         index: 0
                     };
                     var t = 0,
                         r = n.parentElement;
                     if (r)
                         for (var i = 0; i < r.children.length && r.children[i] !== n; i++) r.children[i].nodeName === n.nodeName && t++;
                     return {
                         str: [n.nodeName.toLowerCase(), e(n) ? "[]" : ""].join(""),
                         index: t
                     }
                 }(n),
                 o = t.str,
                 a = t.index;
             r.unshift(o), i.unshift(a)
         })), {
             element_path: "/".concat(r.join("/")),
             positions: i
         }
     }
     var t = window.__TEA_CHUNK_MAX__ || 524288;

     function r(e) {
         try {
             return new Blob([e]).size
         } catch (i) {
             for (var n = e.length, t = n - 1; t >= 0; t--) {
                 var r = e.charCodeAt(t);
                 r > 127 && r <= 2047 ? n++ : r > 2047 && r <= 65535 && (n += 2), r >= 56320 && r <= 57343 && t--
             }
             return n
         }
     }

     function i(e) {
         if (r(e) < t) return [e];
         var n = encodeURIComponent(e),
             i = Math.ceil(r(n) / t);
         return new Array(i).fill("").map((function(e, r) {
             return n.substr(r * t, t)
         }))
     }
     var o = !1,
         a = 1,
         u = window.innerWidth,
         c = window.innerHeight,
         f = new Set;
     var l = function(e) {
             var n = e._element_path,
                 t = e.positions,
                 r = e.children;
             e._checkList = !0;
             var i = n.split("/").length - 2;
             if (e.fuzzy_positions || (e.fuzzy_positions = [].concat(t)), e.fuzzy_positions[i] = "*", r) {
                 ! function e(n) {
                     n.forEach((function(n) {
                         n.fuzzy_positions || (n.fuzzy_positions = [].concat(n.positions)), n.fuzzy_positions[i] = "*", n.children && e(n.children)
                     }))
                 }(r)
             }
         },
         s = function e(t) {
             return Array.prototype.slice.call(t, 0).reduce((function(t, r) {
                 if (!r) return t;
                 var i = r.nodeName;
                 if (function(e) {
                         return ["script", "link", "style", "embed"].includes(e)
                     }(i = i.toLowerCase()) || function(e) {
                         var n = getComputedStyle(e, null);
                         if ("none" === n.getPropertyValue("display")) return !0;
                         if ("0" === n.getPropertyValue("opacity")) return !0;
                         return !1
                     }(r)) return t;
                 var o = {};
                 if (! function(e) {
                         return ["button", "select"].includes(e)
                     }(i) && r.children) {
                     var s = e(r.children);
                     s && s.length && (o = {
                         children: s
                     })
                 }
                 var h = function(e) {
                     var n = arguments.length > 1 && void 0 !== arguments[1] ? arguments[1] : 1,
                         t = e.getBoundingClientRect().toJSON();
                     if (1 === n) return t;
                     return Object.keys(t).reduce((function(e, r) {
                         return e[r] = Math.ceil(t[r] * n), e
                     }), {})
                 }(r, a);
                 if (! function(e, n) {
                         var t = e.left,
                             r = e.right,
                             i = e.top,
                             o = e.bottom,
                             a = e.width,
                             u = e.height;
                         if (!(a > 0 && u > 0)) return !1;
                         if (t > window.innerWidth || r < 0 || i > window.innerHeight || o < 0) return !1;
                         return !0
                     }(h)) return o.children && o.children.forEach((function(e) {
                     return t.push(e)
                 })), t;
                 h = function(e) {
                     var n = {
                         x: e.left,
                         y: e.top,
                         width: e.width,
                         height: e.height
                     };
                     return e.top < 0 && (n.y = 0, n.height += e.top), e.bottom > c && (n.height = c - n.y), e.left < 0 && (n.x = 0, n.width += e.left), e.right > u && (n.width = u - n.x), Object.keys(n).forEach((function(e) {
                         n[e] = Math.floor(n[e])
                     })), n
                 }(h);
                 var d = function(e) {
                         var t = n(e),
                             r = t.element_path,
                             i = t.positions.map((function(e) {
                                 return "".concat(e)
                             })),
                             o = [].concat(i).reverse(),
                             a = !1;
                         if (-1 !== r.indexOf("[]")) {
                             a = !0;
                             var u = !1;
                             r.split("/").reverse().forEach((function(e, n) {
                                 u || -1 === e.indexOf("[]") || (u = !0, o[n] = "*")
                             }))
                         }
                         var c = e.id,
                             f = e.tagName,
                             l = ["absolute", "fixed"],
                             s = 0,
                             h = getComputedStyle(e, null).getPropertyValue("z-index");
                         "auto" !== h && (s = parseInt(String(h), 10));
                         for (var d = e.parentElement; d;) {
                             var p = getComputedStyle(d, null);
                             if (l.includes(p.getPropertyValue("position"))) {
                                 s += 1e4;
                                 break
                             }
                             d = d.parentElement
                         }
                         return Object.assign({
                             element_id: c,
                             element_type: f,
                             _element_path: r,
                             element_path: "".concat(r, "/*"),
                             positions: i.concat("*"),
                             zIndex: s
                         }, a ? {
                             fuzzy_positions: o.reverse().concat("*")
                         } : {})
                     }(r),
                     p = d._element_path,
                     v = !1;
                 if (f.has(p)) v = !0;
                 else {
                     var m = r.parentElement;
                     if (m) {
                         var g = m.children,
                             w = Array.from(g).filter((function(e) {
                                 return e.nodeName.toLowerCase() === i
                             })),
                             y = w.length;
                         if (y >= 3) {
                             var _ = Array.from(r.classList),
                                 b = _.length,
                                 z = Array.from(r.children).map((function(e) {
                                     return e.nodeName.toLowerCase()
                                 })).join(","),
                                 A = 0;
                             Array.from(w).forEach((function(e) {
                                 if (e === r) return A++, void 0;
                                 var n = !1;
                                 if (b) {
                                     var t = Array.from(e.classList);
                                     _.length + t.length - new Set([].concat(t, _)).size > 0 && (n = !0)
                                 } else n = !0;
                                 if (n) {
                                     var i = !1;
                                     if (z) {
                                         var o = Array.from(e.children).map((function(e) {
                                             return e.nodeName.toLowerCase()
                                         })).join(",");
                                         o === z && (i = !0)
                                     } else i = !0;
                                     i && A++
                                 }
                             })), A >= 3 && A / y >= .5 && (v = !0), v && f.add(p)
                         }
                     }
                 }
                 return d = Object.assign(Object.assign({
                     nodeName: i,
                     frame: h
                 }, d), o), v && l(d), d.children && d.children.forEach((function(e) {
                     var n = e._element_path,
                         t = e._checkList;
                     f.has(n) && !t && l(e)
                 })), t.push(d), t
             }), [])
         },
         h = function() {
             if (o) return;
             o = !0, a = function() {
                 try {
                     var e = window.outerWidth / window.innerWidth;
                     if (1 === e) return 1;
                     if (e) return e;
                     var n = document.querySelector('meta[name="viewport"]');
                     if (n) {
                         var t = n.content.match(/initial-scale=(.*?)(,|$)/);
                         if (t && t[1]) {
                             var r = parseFloat(t[1]);
                             if (r) return r
                         }
                     }
                 } catch (e) {
                     return 1
                 }
                 return 1
             }(), u = window.innerWidth * a, c = window.innerHeight * a, f = new Set
         },
         d = function(e) {
             return JSON.stringify(e)
         };
     if (!window.TEAWebviewInfo) {
         var p = [],
             v = function() {
                 var e = arguments.length > 0 && void 0 !== arguments[0] && arguments[0];
                 if (p.length) return console.log(p.length, p), d({
                     value: p.shift(),
                     done: !p.length
                 });
                 h();
                 try {
                     var n = s(document.querySelectorAll("body > *")),
                         t = {
                             page: window.location.href,
                             info: n
                         },
                         r = d(t);
                     if (console.log(r), !e) return r;
                     if (1 === (p = i(r)).length) return p.shift();
                     return console.log(p.length, p), d({
                         value: p.shift(),
                         done: !1
                     })
                 } catch (e) {
                     console.log(e)
                 }
                 return ""
             };
         v.version = "1.2.2", window.TEAWebviewInfo = v
     }
 }());

    );
    #undef __picker_js_func__
    return bdPickerJSCode;
}
