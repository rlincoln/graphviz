import 'dart:html';
import 'dart:svg';
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
      var svgNode = document.importNode(doc.documentElement, true);
      output.append(svgNode);

      if (svgNode is SvgSvgElement) {
        processSvgDocument(svgNode);
      }
    });
  }

  querySelector('#layout').onClick.listen(submitForm);
}

void processSvgDocument(SvgSvgElement svg) {
  removeTitles(svg);
  addDropShadow(svg);
  addClickListeners(svg, (MouseEvent e) {
    print('NODE: ${e.target}');
  }, (MouseEvent e) {
    print('EDGE: ${e.target}');
  });
}

void removeTitles(SvgSvgElement svg) {
  svg.querySelectorAll('title').forEach((Element title) {
    title.remove();
  });
}

void addDropShadow(SvgSvgElement svg) {
  svg.append(dropShadow);
  svg.querySelectorAll('.node').forEach((Element elem) {
    //elem.querySelector('title + *').style.filter = 'url(#dropshadow)';
    elem.children.first.style.filter = 'url(#dropshadow)';
  });
}

void addClickListeners(SvgSvgElement svg, Function onNode, Function onEdge) {
  svg.querySelectorAll('.node').forEach((Element elem) {
    elem.onClick.listen(onNode);
  });
  svg.querySelectorAll('.edge').forEach((Element elem) {
    elem.onClick.listen(onEdge);
  });
}

final dropShadow = new SvgElement.svg('''
<filter id="dropshadow" height="130%">
  <feGaussianBlur in="SourceAlpha" stdDeviation="3"/>
  <feOffset dx="2" dy="2" result="offsetblur"/>
  <feMerge> 
    <feMergeNode/>
    <feMergeNode in="SourceGraphic"/>
  </feMerge>
</filter>
''');