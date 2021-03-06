import 'dart:html';
import 'package:charted/charted.dart';
import 'package:graphviz/zoom.dart';

main() {
  var margin = {'top': 20, 'right': 20, 'bottom': 30, 'left': 40},
      width = 960 - margin['left'] - margin['right'],
      height = 500 - margin['top'] - margin['bottom'];

  var x = new LinearScale()
      ..domain = [-width / 2, width / 2]
      ..range = [0, width];

  var y = new LinearScale()
      ..domain = [-height / 2, height / 2]
      ..range = [height, 0];

  var xAxis = new SvgAxis()
      ..scale = x
      ..orientation = "bottom"
      ..innerTickSize = -height;

  var yAxis = new SvgAxis()
      ..scale = y
      ..orientation = "left"
      ..suggestedTickCount = 5
      ..innerTickSize = -width;

  var svg = new SelectionScope.selector("body")
    .append("svg:svg")
      ..attr("width", width + margin['left'] + margin['right'])
      ..attr("height", height + margin['top'] + margin['bottom']);
  var g = svg.append("g")
      ..attr("transform", "translate(${margin['left']},${margin['top']})");
//      ..call(zoom);

  var zoom = new Zoom(g)
      ..x = x
      ..y = y
      ..scaleExtent = [1, 10];

  g.append("rect")
      ..attr("width", width)
      ..attr("height", height);

  xAxis.axis(g.append("g")
      ..attr("class", "x axis")
      ..attr("transform", "translate(0,$height)"));
//      ..call(xAxis);

  yAxis.axis(g.append("g")
      ..attr("class", "y axis"));
//      ..call(yAxis);

  zoomed([_]) {
//    g.select(".x.axis").call(xAxis);
//    g.select(".y.axis").call(yAxis);
    xAxis.axis(g.select(".x.axis"));
    yAxis.axis(g.select(".y.axis"));
  }

//  zoom.on("zoom", zoomed);
  zoom.onZoom.listen(zoomed);

  reset(_) {
    new Transition(g)
      ..duration(750)
      ..attrTween("zoom", (d, ei, String attr) {
      var ix = interpolateList(x.domain, [-width / 2, width / 2]),
          iy = interpolateList(y.domain, [-height / 2, height / 2]);
      return (num t) {
        zoom.x = (x..domain = ix(t));
        zoom.y = (y..domain = iy(t));
        zoomed();
      };
    });
  }

  querySelector("button").onClick.listen(reset);
}
