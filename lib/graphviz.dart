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

class GraphvizNaClModule extends AsyncNaClModule {

  factory GraphvizNaClModule.selector(String selector) {
    var wrapper = document.querySelector(selector);
    return new GraphvizNaClModule(wrapper);
  }
  
  GraphvizNaClModule(Element wrapper) : super(wrapper, 'graphviz',
      '/packages/graphviz/pnacl/Release');

  Future<GraphvizOutput> dot(String dotdata, {Render render: Render.SVG,
      Layout layout: Layout.DOT, bool verbose: false}) {
    return runCommand('dot', [
      dotdata,
      _toStringRender(render),
      _toStringLayout(layout),
      verbose ? 1 : 0
    ]).then((retval) {
      if (retval.length != 2) {
        throw new ArgumentError.value(retval, 'retval', 'expected: 2 actual: ${retval.length}');
      }
      return new GraphvizOutput(retval[0], retval[1]);
    });
  }
}

class GraphvizOutput {
  final String output, log;
  GraphvizOutput(this.output, this.log);
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