import 'dart:html';
import 'package:graphviz/graphviz.dart';
import 'package:graphviz/graphs.dart';

main() {
  final code = querySelector('#code');
  final module = new GraphvizNaClModule.selector('#listener');
  module.dot(cluster, render: Render.SVG, layout: Layout.DOT,
      verbose: true).then((GraphvizOutput out) {
    code.text = '${out.log}';
    final doc = new DomParser().parseFromString(out.output, 'text/xml');
    document.body.append(document.importNode(doc.documentElement, true));
  });
}
