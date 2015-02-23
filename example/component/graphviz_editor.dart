import 'dart:html';

import 'package:polymer/polymer.dart';
import 'package:graphviz/components/graphviz_module.dart';
import 'package:graphviz/graphs.dart';

@CustomTag('graphviz-editor')
class GraphvizEditor extends PolymerElement {
  @published String module;
  @published String dot = simple;
  @published String layoutType = 'dot';
  
  GraphvizModule _graphvizModule;

  GraphvizEditor.created() : super.created();

  void ready() {
    if (module == null) {
      throw new ArgumentError.notNull('module');
    }
    _graphvizModule = document.querySelector('#$module');
  }
  
  void layout(e, detail, target) {
    _graphvizModule.dot = dot;
  }
}