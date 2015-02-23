import 'dart:html';
import 'package:graphviz/graphviz.dart';
import 'package:graphviz/graphs.dart';

main() {
  var module = new GraphvizNaClModule.selector('#listener');

  var layoutSelect = querySelector('#layouts');
  var graphSelect = querySelector('#graphs');
  var output = querySelector('#output');

  var graphs = {
    'simple': simple,
    'cluster': cluster
  };

  void submitForm(Event e) {
    e.preventDefault();
    module.dot(graphs[graphSelect.value],
        layout: parseLayout(layoutSelect.value),
        verbose: true).then((GraphvizOutput out) {
      querySelector('#code').text = '${out.log}';

      final doc = new DomParser().parseFromString(out.output, 'text/xml');
      while (output.firstChild != null) {
        output.firstChild.remove();
      }
      output.append(document.importNode(doc.documentElement, true));
    });
  }

  querySelector('#layout').onClick.listen(submitForm);
}