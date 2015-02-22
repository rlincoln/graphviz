library graphviz.components.nacl_module;

import 'dart:html';
import 'dart:async';

import 'package:polymer/polymer.dart';

//import 'package:ppapi_common/nacl_module.dart';
import '../graphviz.dart';

@CustomTag('graphviz-module')
class GraphvizModule extends PolymerElement {//with Observable {
  @published String layout;
  @published num width, height;
  @published String text;
  
  DivElement _listener;
  GraphvizNaClModule _module;
  
  final _parser = new DomParser();

  GraphvizModule.created() : super.created();

  void ready() {
    Polymer.onReady.then((_) {
      return new Future(_polymerReady);
    });
  }
  
  void _polymerReady() {
    if (text == null) {
      text = super.text;
    }
    _listener = this.$['listener'] as DivElement;
    _module = new GraphvizNaClModule(_listener)
      ..width = width
      ..height = height
      ..component = this.shadowRoot;
//    this.text = cluster;
  }
  
  void attributeChanged(name, old, n) {
    print('attr: $name');
  }
  
  void textChanged(old, String newText) {
    print('text: $old $newText');
    _module.dot(newText, layout: Layout.DOT).then((out) {
      print('out: ${out.output}');
      final doc = _parser.parseFromString(out.output, 'text/xml');
      document.body.append(document.importNode(doc.documentElement, true));      
    });
  }
}

final cluster = '''digraph G {

  subgraph cluster_0 {
    style=filled;
    color=lightgrey;
    node [style=filled,color=white];
    a0 -> a1 -> a2 -> a3;
    label = "process #1";
  }

  subgraph cluster_1 {
    node [style=filled];
    b0 -> b1 -> b2 -> b3;
    label = "process #2";
    color=blue
  }
  start -> a0;
  start -> b0;
  a1 -> b3;
  b2 -> a3;
  a3 -> a0;
  a3 -> end;
  b3 -> end;

  start [shape=Mdiamond];
  end [shape=Msquare];
}''';