library graphviz.module;

import 'dart:html';
import 'dart:async';
import 'package:ppapi_common/nacl_module.dart';

class GraphvizModule extends AsyncNaClModule {

  factory GraphvizModule(String selector) {
    var wrapper = document.querySelector(selector);
    return new GraphvizModule._internal(wrapper);
  }
  
  GraphvizModule._internal(wrapper) : super(wrapper, 'graphviz', '/packages/graphviz/pnacl/Release');

  Future dot(String dotdata) {
    return runCommand('dot', [dotdata]);
  }
}