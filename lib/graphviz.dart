library graphviz.module;

import 'dart:html';
import 'dart:async';
import 'package:ppapi_common/nacl_module.dart';

enum Render {
  PS, SVG, VML, XDOT
}

enum Layout {
  DOT, NEATO
}

class GraphvizModule extends AsyncNaClModule {

  factory GraphvizModule(String selector) {
    var wrapper = document.querySelector(selector);
    return new GraphvizModule._internal(wrapper);
  }
  
  GraphvizModule._internal(wrapper) : super(wrapper, 'graphviz',
      '/packages/graphviz/pnacl/Release');

  Future dot(String dotdata, {Render render: Render.XDOT,
      Layout layout: Layout.DOT, bool verbose: false}) {
    return runCommand('dot', [
      dotdata,
      _toStringRender(render),
      _toStringLayout(layout),
      verbose ? 1 : 0
    ]);
  }
}

String _toStringRender(Render render) {
  String s;
  switch (render) {
    case Render.PS:
      s = 'ps';
      break;
    case Render.SVG:
      s = 'svg';
      break;
    case Render.VML:
      s = 'vml';
      break;
    case Render.XDOT:
      s = 'xdot';
      break;
  }
  return s;
}

String _toStringLayout(Layout layout) {
  String s;
  switch (layout) {
    case Layout.DOT:
      s = 'dot';
      break;
    case Layout.NEATO:
      s = 'neato';
      break;
  }
  return s;
}