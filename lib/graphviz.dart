library graphviz.module;

import 'dart:html';
import 'dart:async';
import 'package:ppapi_common/nacl_module.dart';

enum Render {
  DOT, FIG, MAP, PIC, POV, TK, PS, SVG, VML, XDOT
}

enum Layout {
  DOT, NEATO, CIRCO, FDP, NOP, NOP1, NOP2, OSAGE, PATCHWORK, SFDP, TWOPI
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
      render.toString().split('.').last.toLowerCase(),
      layout.toString().split('.').last.toLowerCase(),
      verbose ? 1 : 0
    ]).then((retval) {
      if (retval.length != 2) {
        throw new ArgumentError.value(retval, 'retval',
            'expected: 2 actual: ${retval.length}');
      }
      return new GraphvizOutput(retval[0], retval[1]);
    });
  }
}

class GraphvizOutput {
  final String output, log;
  GraphvizOutput(this.output, this.log);
}

Layout parseLayout(String l) {
  switch (l.toLowerCase()) {
    case 'dot':
      return Layout.DOT;
    case 'neato':
      return Layout.NEATO;
    case 'circo':
      return Layout.CIRCO;
    case 'fdp':
      return Layout.FDP;
    case 'nop':
      return Layout.NOP;
    case 'nop1':
      return Layout.NOP1;
    case 'nop2':
      return Layout.NOP2;
    case 'osage':
      return Layout.OSAGE;
    case 'patchwork':
      return Layout.PATCHWORK;
    case 'sfdp':
      return Layout.SFDP;
    case 'twopi':
      return Layout.TWOPI;
    default:
      throw new ArgumentError.value(l);
  }
}