library graphviz.components.nacl_module;

import 'dart:html';
import 'dart:async';

import 'package:polymer/polymer.dart';

//import 'package:ppapi_common/nacl_module.dart';
import '../graphviz.dart';

@CustomTag('graphviz-module')
class GraphvizModule extends PolymerElement {//with Observable {
  @published String layout;
  @published num width = 0, height = 0;
  @published String dot;
  
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
    if (dot == null) {
      dot = text;
    }
    _listener = this.$['listener'] as DivElement;
    _module = new GraphvizNaClModule(_listener)
      ..width = width
      ..height = height
      ..component = this.shadowRoot;
  }
  
  void dotChanged(old, String newText) {
    print('text: $old $newText');
    _module.dot(newText, layout: Layout.DOT).then((out) {
      print('out: ${out.output}');
      final doc = _parser.parseFromString(out.output, 'text/xml');
      final node = document.importNode(doc.documentElement, true);
      final output = this.$['output'] as Element;
      while (output.firstChild != null) {
        output.firstChild.remove();
      }
      output.append(node);
    });
  }
  
  void set text(String t) {
    dot = t;
    super.text = t;
  }
}
