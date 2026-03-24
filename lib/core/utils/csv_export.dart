import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:csv/csv.dart';

void exportToCSV(
    String filename, List<String> headers, List<List<dynamic>> rows) {
  final csvData = [headers, ...rows];
  final csvString = const ListToCsvConverter().convert(csvData);
  final bytes = utf8.encode(csvString);
  final blob = html.Blob([bytes], 'text/csv;charset=utf-8');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..style.display = 'none';
  html.document.body?.children.add(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);
}
