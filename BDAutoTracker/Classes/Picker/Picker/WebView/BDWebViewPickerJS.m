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
 !(function () {
   "use strict";
   function t(t) {
     return (
       (function (t) {
         if (Array.isArray(t)) return e(t);
       })(t) ||
       (function (t) {
         if ("undefined" != typeof Symbol && Symbol.iterator in Object(t))
           return Array.from(t);
       })(t) ||
       (function (t, n) {
         if (!t) return;
         if ("string" == typeof t) return e(t, n);
         var r = Object.prototype.toString.call(t).slice(8, -1);
         "Object" === r && t.constructor && (r = t.constructor.name);
         if ("Map" === r || "Set" === r) return Array.from(t);
         if (
           "Arguments" === r ||
           /^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(r)
         )
           return e(t, n);
       })(t) ||
       (function () {
         throw new TypeError(
           "Invalid attempt to spread non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method."
         );
       })()
     );
   }
   function e(t, e) {
     (null == e || e > t.length) && (e = t.length);
     for (var n = 0, r = new Array(e); n < e; n++) r[n] = t[n];
     return r;
   }
   function n(t) {
     if (["LI", "TR", "DL"].includes(t.nodeName)) return !0;
     if (t.dataset && t.dataset.hasOwnProperty("teaIdx")) return !0;
     if (t.hasAttribute && t.hasAttribute("data-tea-idx")) return !0;
     return !1;
   }
   function r(t) {
     if (!t) return !1;
     if (["A", "BUTTON"].includes(t.nodeName)) return !0;
     if (t.dataset && t.dataset.hasOwnProperty("teaContainer")) return !0;
     if (t.hasAttribute && t.hasAttribute("data-tea-container")) return !0;
     return !1;
   }
   function i(t) {
     for (var e = t; e && !r(e); ) {
       if ("HTML" === e.nodeName || "BODY" === e.nodeName) return t;
       e = e.parentElement;
     }
     return e || t;
   }
   function o(t) {
     for (var e = []; null !== t.parentElement; )
       e.push(t), (t = t.parentElement);
     var r = [],
       i = [];
     return (
       e.forEach(function (t) {
         var e = (function (t) {
             if (null === t) return { str: "", index: 0 };
             var e = 0,
               r = t.parentElement;
             if (r)
               for (var i = 0; i < r.children.length && r.children[i] !== t; i++)
                 r.children[i].nodeName === t.nodeName && e++;
             return {
               str: [t.nodeName.toLowerCase(), n(t) ? "[]" : ""].join(""),
               index: e,
             };
           })(t),
           o = e.str,
           a = e.index;
         r.unshift(o), i.unshift(a);
       }),
       { element_path: "/".concat(r.join("/")), positions: i }
     );
   }
   function a(t) {
     var e = { element_path: "", positions: [], texts: [] },
       n = o(t),
       r = n.element_path,
       a = n.positions,
       u = (function (t) {
         var e = i(t),
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
               for (var i = e.childNodes, o = 0; o < i.length; o++)
                 8 !== i[o].nodeType && t(i[o]);
           })(e),
           n
         );
       })(t);
     (e.element_path = r),
       (e.positions = a.map(function (t) {
         return "".concat(t);
       })),
       (e.texts = u);
     var c = i(t);
     if (
       ("A" === c.tagName && (e.href = c.getAttribute("href")),
       "IMG" === t.tagName)
     ) {
       var l = t.getAttribute("src");
       l && 0 === l.trim().indexOf("data:") && (l = ""), (e.src = l);
     }
     return (
       (e.page_title = document.title),
       (e.element_id = t.id),
       (e.element_type = t.tagName),
       e
     );
   }
   var u = window.__TEA_CHUNK_MAX__ || 524288;
   function c(t) {
     try {
       return new Blob([t]).size;
     } catch (i) {
       for (var e = t.length, n = e - 1; n >= 0; n--) {
         var r = t.charCodeAt(n);
         r > 127 && r <= 2047 ? e++ : r > 2047 && r <= 65535 && (e += 2),
           r >= 56320 && r <= 57343 && n--;
       }
       return e;
     }
   }
   function l(t) {
     if (c(t) < u) return [t];
     var e = encodeURIComponent(t),
       n = Math.ceil(c(e) / u);
     return new Array(n).fill("").map(function (t, n) {
       return e.substr(n * u, u);
     });
   }
   var f = function (t) {
       var e = a(t),
         n = e.element_path,
         r = e.positions,
         i = e.texts,
         o = e.href,
         u = e.src,
         c = (function (t, e) {
           var n = {};
           for (var r in t)
             Object.prototype.hasOwnProperty.call(t, r) &&
               e.indexOf(r) < 0 &&
               (n[r] = t[r]);
           if (null != t && "function" == typeof Object.getOwnPropertySymbols) {
             var i = 0;
             for (r = Object.getOwnPropertySymbols(t); i < r.length; i++)
               e.indexOf(r[i]) < 0 &&
                 Object.prototype.propertyIsEnumerable.call(t, r[i]) &&
                 (n[r[i]] = t[r[i]]);
           }
           return n;
         })(e, ["element_path", "positions", "texts", "href", "src"]),
         l = [].concat(r).reverse(),
         f = !1;
       if (-1 !== n.indexOf("[]")) {
         f = !0;
         var s = !1;
         n.split("/")
           .reverse()
           .forEach(function (t, e) {
             s || -1 === t.indexOf("[]") || ((s = !0), (l[e] = "*"));
           });
       }
       var d = ["absolute", "fixed"],
         h = 0,
         p = getComputedStyle(t, null).getPropertyValue("z-index");
       "auto" !== p && (h = parseInt(String(p), 10));
       for (var m = t.parentElement; m; ) {
         var g = getComputedStyle(m, null);
         if (d.includes(g.getPropertyValue("position"))) {
           h += 1e4;
           break;
         }
         m = m.parentElement;
       }
       return Object.assign(
         Object.assign(
           Object.assign(
             Object.assign(Object.assign({}, c), {
               _element_path: n,
               element_path: "".concat(n, "/*"),
               positions: r.concat("*"),
               zIndex: h,
               texts: i,
             }),
             f ? { fuzzy_positions: l.reverse().concat("*") } : {}
           ),
           o ? { href: o } : {}
         ),
         u ? { src: u } : {}
       );
     },
     s = !1,
     d = 1,
     h = window.innerWidth,
     p = window.innerHeight,
     m = new Set();
   var g = function (t) {
       var e = t._element_path,
         n = t.positions,
         r = t.children;
       t._checkList = !0;
       var i = e.split("/").length - 2;
       if (
         (t.fuzzy_positions || (t.fuzzy_positions = [].concat(n)),
         (t.fuzzy_positions[i] = "*"),
         r)
       ) {
         !(function t(e) {
           e.forEach(function (e) {
             e.fuzzy_positions || (e.fuzzy_positions = [].concat(e.positions)),
               (e.fuzzy_positions[i] = "*"),
               e.children && t(e.children);
           });
         })(r);
       }
     },
     y = function e(n) {
       return Array.prototype.slice.call(n, 0).reduce(function (n, r) {
         if (!r) return n;
         var i = r.nodeName;
         if (
           (function (t) {
             return ["script", "link", "style", "embed"].includes(t);
           })((i = i.toLowerCase())) ||
           (function (t) {
             var e = getComputedStyle(t, null);
             if ("none" === e.getPropertyValue("display")) return !0;
             if ("0" === e.getPropertyValue("opacity")) return !0;
             return !1;
           })(r)
         )
           return n;
         var o = (function (t) {
           var e =
               arguments.length > 1 && void 0 !== arguments[1]
                 ? arguments[1]
                 : 1,
             n = t.getBoundingClientRect().toJSON();
           if (1 === e) return n;
           return Object.keys(n).reduce(function (t, r) {
             return (t[r] = Math.ceil(n[r] * e)), t;
           }, {});
         })(r, d);
         if (
           !(function (t, e) {
             var n = t.left,
               r = t.right,
               i = t.top,
               o = t.bottom,
               a = t.width,
               u = t.height,
               c = !(a > 0 && u > 0),
               l = getComputedStyle(e, null);
             if (!["", "static"].includes(l.getPropertyValue("position"))) {
               if (c && !e.children.length) return !1;
               var f = l.getPropertyValue("z-index");
               if ("auto" !== f && parseInt(f, 10) < 0) return !1;
               return !0;
             }
             if (c) return !1;
             if (
               n > window.innerWidth ||
               r < 0 ||
               i > window.innerHeight ||
               o < 0
             )
               return !1;
             return !0;
           })(o, r)
         )
           return n;
         o = (function (t) {
           var e = { x: t.left, y: t.top, width: t.width, height: t.height };
           return (
             t.top < 0 && ((e.y = 0), (e.height += t.top)),
             t.bottom > p && (e.height = p - e.y),
             t.left < 0 && ((e.x = 0), (e.width += t.left)),
             t.right > h && (e.width = h - e.x),
             Object.keys(e).forEach(function (t) {
               e[t] = Math.floor(e[t]);
             }),
             e
           );
         })(o);
         var a = {};
         if (
           !(function (t) {
             return ["button", "select"].includes(t);
           })(i) &&
           r.children
         ) {
           var u = e(r.children);
           u && u.length && (a = { children: u });
         }
         var c = f(r),
           l = c._element_path,
           s = !1;
         if (m.has(l)) s = !0;
         else {
           var y = r.parentElement;
           if (y) {
             var v = y.children,
               b = Array.from(v).filter(function (t) {
                 return t.nodeName.toLowerCase() === i;
               }),
               w = b.length;
             if (w >= 3) {
               var A = Array.from(r.classList),
                 _ = A.length,
                 O = Array.from(r.children)
                   .map(function (t) {
                     return t.nodeName.toLowerCase();
                   })
                   .join(","),
                 x = 0;
               Array.from(b).forEach(function (e) {
                 if (e === r) return x++, void 0;
                 var n = !1;
                 if (_) {
                   var i = Array.from(e.classList);
                   A.length + i.length - new Set([].concat(t(i), t(A))).size >
                     0 && (n = !0);
                 } else n = !0;
                 if (n) {
                   var o = !1;
                   if (O)
                     Array.from(e.children)
                       .map(function (t) {
                         return t.nodeName.toLowerCase();
                       })
                       .join(",") === O && (o = !0);
                   else o = !0;
                   o && x++;
                 }
               }),
                 x >= 3 && x / w >= 0.5 && (s = !0),
                 s && m.add(l);
             }
           }
         }
         return (
           (c = Object.assign(Object.assign({ nodeName: i, frame: o }, c), a)),
           s && g(c),
           c.children &&
             c.children.forEach(function (t) {
               var e = t._element_path,
                 n = t._checkList;
               m.has(e) && !n && g(t);
             }),
           n.push(c),
           n
         );
       }, []);
     },
     v = function () {
       if (s) return;
       (s = !0),
         (d = (function () {
           try {
             var t = window.outerWidth / window.innerWidth;
             if (1 === t) return 1;
             if (t) return t;
             var e = document.querySelector('meta[name="viewport"]');
             if (e) {
               var n = e.content.match(/initial-scale=(.*?)(,|$)/);
               if (n && n[1]) {
                 var r = parseFloat(n[1]);
                 if (r) return r;
               }
             }
           } catch (t) {
             return 1;
           }
           return 1;
         })()),
         (h = window.innerWidth * d),
         (p = window.innerHeight * d),
         (m = new Set());
     },
     b = function (t) {
       return JSON.stringify(t);
     };
   if (!window.TEAWebviewInfo) {
     var w = [],
       A = function () {
         var t = arguments.length > 0 && void 0 !== arguments[0] && arguments[0];
         if (w.length)
           return (
             console.log(w.length, w), b({ value: w.shift(), done: !w.length })
           );
         v();
         try {
           var e = y(document.querySelectorAll("body > *")),
             n = { page: window.location.href, info: e },
             r = b(n);
           if ((console.log(r), !t)) return r;
           if (1 === (w = l(r)).length) return w.shift();
           return console.log(w.length, w), b({ value: w.shift(), done: !1 });
         } catch (t) {
           console.log(t);
         }
         return "";
       };
     (A.version = "1.2.0"), (window.TEAWebviewInfo = A);
   }
 })();

    );
    #undef __picker_js_func__
    return bdPickerJSCode;
}
