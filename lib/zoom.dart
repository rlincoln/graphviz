// Copyright (c) 2015, Michael Bostock
// All rights reserved.
library graphviz.zoom;

import 'dart:svg';
import 'dart:html' show Element;
import 'dart:math' as math;
import 'package:charted/charted.dart';

//import "../core/document";
//import "../core/rebind";
//import "../event/drag";
//import "../event/event";
//import "../event/mouse";
//import "../event/touches";
//import "../selection/selection";
//import "../interpolate/zoom";
//import "behavior";

class _View {
  num x, y, k;
  _View({this.x, this.y, this.k});
}

/// This behavior automatically creates event listeners to handle zooming
/// and panning gestures on a container element. Both mouse and touch events
/// are supported.
class Zoom {
  _View view = new _View(x: 0, y: 0, k: 1);
  var _translate0; // translate when we started zooming (to avoid drift)
  List<num> _center0; // implicit desired position of translate0 after zooming
  List<num> _center; // explicit desired position of translate0 after zooming
  List<num> _size = [960, 500]; // viewport size; required for zoom interpolation
  List<num> _scaleExtent = d3_behavior_zoomInfinity;
  int duration = 250;
  bool _zooming = false;
  String _mousedown = "mousedown.zoom";
  String _mousemove = "mousemove.zoom";
  String _mouseup = "mouseup.zoom";
  var _mousewheelTimer;
  String _touchstart = "touchstart.zoom";
  num _touchtime; // time of last touchstart (to detect double-tap)
//      _event = d3_eventDispatch(zoom, "zoomstart", "zoom", "zoomend"),
  Scale _x0;
  Scale _x1;
  Scale _y0;
  Scale _y1;

//  Zoom() {
    // Lazily determine the DOM’s support for Wheel events.
    // https://developer.mozilla.org/en-US/docs/Mozilla_event_reference/wheel
//    if (!d3_behavior_zoomWheel) {
//      d3_behavior_zoomWheel = "onwheel" in d3_document ? (d3_behavior_zoomDelta = function() { return -d3.event.deltaY * (d3.event.deltaMode ? 120 : 1); }, "wheel")
//          : "onmousewheel" in d3_document ? (d3_behavior_zoomDelta = function() { return d3.event.wheelDelta; }, "mousewheel")
//          : (d3_behavior_zoomDelta = function() { return -d3.event.detail; }, "MozMousePixelScroll");
//    }
//  }

  SelectionScope _scope;

  /// Applies the zoom behavior to the specified selection, registering the
  /// necessary event listeners to support panning and zooming.
  Zoom(Selection g) {
    _scope = g.scope;

    g ..on(_mousedown, _mousedowned);
//      ..on(d3_behavior_zoomWheel + ".zoom", _mousewheeled)
//      ..on("dblclick.zoom", _dblclicked)
//      ..on(_touchstart, _touchstarted);
  }

  /// If [g] is a selection, immediately dispatches a zoom gesture to
  /// registered listeners, as the three event sequence zoomstart, zoom and
  /// zoomend.
  ///
  /// If [g] is a transition, registers the appropriate tweens so that the
  /// zoom behavior dispatches events over the course of the transition:
  /// a zoomstart event when the transition starts from the previously-set
  /// view, zoom events for each tick of the transition, and finally a
  /// zoomend event when the transition ends.
  event(Selection g) {
    g.each((dat, i, elem) {
      var dispatch = event.of(this, arguments);
      _View view1 = view;
      if (d3_transitionInheritId) {
        d3.select(this).transition()
            .each("start.zoom", () {
              view = this.__chart__ || new _View(x: 0, y: 0, k: 1); // pre-transition state
              _zoomstarted(dispatch);
            })
            .tween("zoom:zoom", () {
              var dx = size[0],
                  dy = size[1],
                  cx = _center0 ? _center0[0] : dx / 2,
                  cy = _center0 ? _center0[1] : dy / 2,
                  i = d3.interpolateZoom(
                    [(cx - view.x) / view.k, (cy - view.y) / view.k, dx / view.k],
                    [(cx - view1.x) / view1.k, (cy - view1.y) / view1.k, dx / view1.k]
                  );
              return (t) {
                var l = i(t), k = dx / l[2];
                this.__chart__ = view = new _View(x: cx - l[0] * k, y: cy - l[1] * k, k: k);
                _zoomed(dispatch);
              };
            })
            .each("interrupt.zoom", () {
              _zoomended(dispatch);
            })
            .each("end.zoom", () {
              _zoomended(dispatch);
            });
      } else {
        this.__chart__ = view;
        _zoomstarted(dispatch);
        _zoomed(dispatch);
        _zoomended(dispatch);
      }
    });
  }

  /// the current translation vector, which defaults to [0, 0].
  List<num> get translate => [view.x, view.y];

  /// Specifies the current zoom translation vector.
  void set translate(List<num> t) {
    view = new _View(x: t[0], y: t[1], k: view.k); // copy-on-write
    _rescale();
  }

  /// The current zoom scale, which defaults to 1.
  num get scale => view.k;

  /// Specifies the current zoom scale.
  void set scale(num s) {
    view = new _View(x: view.x, y: view.y, k: s); // copy-on-write
    _rescale();
  }

  /// The current scale extent, which defaults to [0, Infinity].
  List<num> get scaleExtent => _scaleExtent;

  /// Specifies the zoom scale's allowed range as a two-element array,
  /// [minimum, maximum].
  void set scaleExtent(List<num> x) {
    if (x == null) {
      x = d3_behavior_zoomInfinity;
    }
    _scaleExtent = [x[0], x[1]];
  }

  /// Current focal point, which defaults to null.
  List<num> get center => _center;

  /// Sets the focal point [x, y] for mousewheel zooming. A null center
  /// indicates that mousewheel zooming should zoom in and out around
  /// the current mouse location.
  void set center(List<num> c) {
    _center = c == null ? c : [c[0], c[1]];
  }

  /// The current viewport size which defaults to [960, 500].
  List<num> get size => _size;

  /// Sets the viewport size to the specified dimensions [width, height]
  /// and returns this zoom behavior. A size is needed to support smooth
  /// zooming during transitions.
  void set size(List<num> s) {
    _size = s == null ? s : [s[0], s[1]];
  }

  /*duration(_) {
    if (!arguments.length) return duration;
    duration = +_; // TODO function based on interpolateZoom distance?
    return zoom;
  }*/

  /// The current x-scale, which defaults to null.
  Scale get x => _x1;

  /// Specifies an x-scale whose domain should be automatically adjusted when
  /// zooming. If the scale's domain or range is modified programmatically,
  /// this function should be called again. Setting the x-scale also resets
  /// the scale to 1 and the translate to [0, 0].
  void set x(Scale z) {
//    if (!arguments.length) return x1;
    _x1 = z;
    _x0 = z.copy();
    view = new _View(x: 0, y: 0, k: 1); // copy-on-write
  }

  /// The current y-scale, which defaults to null.
  Scale get y => _y1;

  /// Specifies an y-scale whose domain should be automatically adjusted when
  /// zooming. If the scale's domain or range is modified programmatically,
  /// this function should be called again. Setting the y-scale also resets
  /// the scale to 1 and the translate to [0, 0].
  void set y(Scale z) {
    _y1 = z;
    _y0 = z.copy();
    view = new _View(x: 0, y: 0, k: 1); // copy-on-write
  }

  List<num> _location(List<num> p) {
    return [(p[0] - view.x) / view.k, (p[1] - view.y) / view.k];
  }

  List<num> _point(List<num> l) {
    return [l[0] * view.k + view.x, l[1] * view.k + view.y];
  }

  void _scaleTo(num s) {
    view.k = math.max(scaleExtent[0], math.min(scaleExtent[1], s));
  }

  void _translateTo(List<num> p, List<num> l) {
    view.x += p[0] - l[0];
    view.y += p[1] - l[1];
  }

  void _zoomTo(that, List<num> p, List<num> l, num k) {
    that.__chart__ = new _View(x: view.x, y: view.y, k: view.k);

    _scaleTo(math.pow(2, k));
    _translateTo(_center0 = p, l);

    that = d3.select(that);
    if (duration > 0) {
      that = that.transition().duration(duration);
    }
    that.call(zoom.event);
  }

  _rescale() {
    if (_x1 != null) {
      _x1.domain(_x0.range().map((x) {
        return (x - view.x) / view.k;
      }).map(_x0.invert));
    }
    if (_y1 != null) {
      _y1.domain(_y0.range().map((y) {
        return (y - view.y) / view.k;
      }).map(_y0.invert));
    }
  }

  void _zoomstarted(dispatch) {
    if (!_zooming) {
      _zooming = true;
      if (dispatch != null) {
        dispatch({
            'type': "zoomstart"
        });
      }
    }
  }

  void _zoomed(dispatch) {
    _rescale();
    if (dispatch != null) {
      dispatch({
          'type': "zoom", 'scale': view.k, 'translate': [view.x, view.y]
      });
    }
  }

  _zoomended(dispatch) {
    if (_zooming) {
      _zooming = false;
      if (dispatch != null) {
        dispatch({
            'type': "zoomend"
        });
      }
    }
    _center0 = null;
  }

  void _mousedowned(dat, i, Element elem) {
    final event = _scope.event;
//    var that = this,
    var target = event.target;
    var dispatch = null;//event.of(that, arguments),
    bool dragged = false;
    final subject = new SelectionScope
      .element(elem.ownerDocument.documentElement)
      .selectAll('*');
//        subject = d3.select(d3_window(that)),
    var location0 = _location(d3_mousePoint(elem, event));
//        dragRestore = d3_event_dragSuppress(that);
//
//    d3_selection_interrupt.call(that);
//    _zoomstarted(dispatch);

    moved(dat, i, el) {
      dragged = true;
      _translateTo(d3_mousePoint(elem, event), location0);
      _zoomed(dispatch);
    }

    ended(dat, i, el) {
      subject
        ..on(_mousemove, null)
        ..on(_mouseup, null);
//      dragRestore(dragged && event.target == target);
      _zoomended(dispatch);
    }

    subject
      ..on(_mousemove, moved)
      ..on(_mouseup, ended);
  }

  // These closures persist for as long as at least one touch is active.
  void _touchstarted(dat, i, elem) {
    var that = this,
        dispatch = event.of(that, arguments),
        locations0 = {}, // touchstart locations
        distance0 = 0, // distance² between initial touches
        scale0, // scale when we started touching
        zoomName = ".zoom-" + d3.event.changedTouches[0].identifier,
        touchmove = "touchmove" + zoomName,
        touchend = "touchend" + zoomName,
        targets = [],
        subject = d3.select(that),
        dragRestore = d3_event_dragSuppress(that);

    // Updates locations of any touches in locations0.
    relocate() {
      var touches = d3.touches(that);
      scale0 = view.k;
      touches.forEach((t) {
        if (locations0.contains(t.identifier)) {
          locations0[t.identifier] = location(t);
        }
      });
      return touches;
    }

    moved() {
      var touches = d3.touches(that),
          p0, l0,
          p1, l1;

      d3_selection_interrupt.call(that);

      for (var i = 0, n = touches.length; i < n; ++i, l1 = null) {
        p1 = touches[i];
        if (l1 = locations0[p1.identifier]) {
          if (l0) break;
          p0 = p1; l0 = l1;
        }
      }

      if (l1) {
        var distance1;
        distance1 = (distance1 = p1[0] - p0[0]) * distance1 + (distance1 = p1[1] - p0[1]) * distance1;
        var scale1 = distance0 && math.sqrt(distance1 / distance0);
        p0 = [(p0[0] + p1[0]) / 2, (p0[1] + p1[1]) / 2];
        l0 = [(l0[0] + l1[0]) / 2, (l0[1] + l1[1]) / 2];
        _scaleTo(scale1 * scale0);
      }

      _touchtime = null;
      _translateTo(p0, l0);
      _zoomed(dispatch);
    }

    ended() {
      // If there are any globally-active touches remaining, remove the ended
      // touches from locations0.
      if (d3.event.touches.length) {
        var changed = d3.event.changedTouches;
        for (var i = 0, n = changed.length; i < n; ++i) {
          locations0.remove(changed[i].identifier);
        }
        // If locations0 is not empty, then relocate and continue listening for
        // touchmove and touchend.
        for (var identifier in locations0) {
          return /*void*/ relocate(); // locations may have detached due to rotation
        }
      }
      // Otherwise, remove touchmove and touchend listeners.
      d3.selectAll(targets).on(zoomName, null);
      subject.on(_mousedown, _mousedowned).on(_touchstart, _touchstarted);
      dragRestore();
      _zoomended(dispatch);
    }

    // Temporarily override touchstart while gesture is active.
    started() {

      // Listen for touchmove and touchend on the target of touchstart.
      var target = d3.event.target;
      d3.select(target).on(touchmove, moved).on(touchend, ended);
      targets.add(target);

      // Only track touches started on the same subject element.
      var changed = d3.event.changedTouches;
      for (var i = 0, n = changed.length; i < n; ++i) {
        locations0[changed[i].identifier] = null;
      }

      var touches = relocate(),
          now = Date.now();

      if (touches.length == 1) {
        if (now - _touchtime < 500) { // dbltap
          var p = touches[0];
          _zoomTo(that, p, locations0[p.identifier], (math.log(view.k) / math.LN2).floor() + 1);
          d3_eventPreventDefault();
        }
        _touchtime = now;
      } else if (touches.length > 1) {
        var p = touches[0], q = touches[1],
            dx = p[0] - q[0], dy = p[1] - q[1];
        distance0 = dx * dx + dy * dy;
      }
    }

    started();
    _zoomstarted(dispatch);

    // Workaround for Chrome issue 412723: the touchstart listener must be set
    // after the touchmove listener.
    subject.on(_mousedown, null).on(_touchstart, started); // prevent duplicate events
  }

  void _mousewheeled(dat, i, elem) {
    var dispatch = event.of(this, arguments);
    if (_mousewheelTimer != null) {
      clearTimeout(mousewheelTimer);
    } else {
//      _translate0 = _location(center0 = center || d3.mouse(this)), d3_selection_interrupt.call(this), _zoomstarted(dispatch);
    }
    _mousewheelTimer = setTimeout(() {
      _mousewheelTimer = null;
      _zoomended(dispatch);
    }, 50);
    d3_eventPreventDefault();
    _scaleTo(math.pow(2, d3_behavior_zoomDelta() * .002) * view.k);
    _translateTo(_center0, _translate0);
    _zoomed(dispatch);
  }

  void _dblclicked(dat, i, elem) {
    var p = d3.mouse(this),
        k = math.log(view.k) / math.LN2;

    _zoomTo(this, p, _location(p), d3.event.shiftKey ? k.ceil() - 1 : k.floor() + 1);
  }

//  return d3.rebind(zoom, event, "on");
}

const d3_behavior_zoomInfinity = const [0, double.INFINITY]; // default scale extent
var d3_behavior_zoomDelta, // initialized lazily
d3_behavior_zoomWheel;

d3_mousePoint(SvgElement container, Event e) {
//  if (e.changedTouches) e = e.changedTouches[0];
  SvgSvgElement svg;
  if (container is SvgSvgElement) {
    svg = container;
  } else {
    svg = container.ownerSvgElement;
  }

  Point point = svg.createSVGPoint();
  /*if (d3_mouse_bug44083 < 0) {
    var window = d3_window(container);
    if (window.scrollX || window.scrollY) {
      svg = d3.select("body").append("svg").style({
      position: "absolute",
      top: 0,
      left: 0,
      margin: 0,
      padding: 0,
      border: "none"
      }, "important");
      var ctm = svg[0][0].getScreenCTM();
      d3_mouse_bug44083 = !(ctm.f || ctm.e);
      svg.remove();
    }
  }*/
  /*if (d3_mouse_bug44083) {
    point.x = e.pageX;
    point.y = e.pageY;
  } else {*/
  point.x = e.clientX
  point.y = e.clientY;
  //}
  point = point.matrixTransform(container.getScreenCTM().inverse());
  return [point.x, point.y];

  //var rect = container.getBoundingClientRect();
  //return [e.clientX - rect.left - container.clientLeft, e.clientY - rect.top - container.clientTop];
};
