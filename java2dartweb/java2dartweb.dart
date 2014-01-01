import 'dart:html';
import 'dart:async';

import 'java2dart.dart';

Element java, dart;


void main() {
  Timer timer = new Timer(new Duration(), translate);

  dart = querySelector("#dart");

  java = querySelector("#java")
    ..onKeyDown.listen((e) {
      print("$e");
      timer.cancel();
      timer = new Timer(new Duration(milliseconds: 500), translate);
    });
}

void translate() {
  String source = (java as TextAreaElement).value;
  try {
    StringBuffer sink = new StringBuffer();
    new Translator(sink).translate(new Parser(source).parseCompilationUnit());
    dart.innerHtml = colorize(sink.toString().replaceAll("&", "&amp;").replaceAll("<", "&lt;").trim());
  } catch (e) {
    dart.text = e.toString();
  }
}

String colorize(String source) {
  const RE =
      r'''(//.*$|/\*[\s\S]*?\*/)|'''
      r'''("(?:\\.|[^"])*"|'(?:\\.|[^'])*'|\d+(?:\.\d*)?(?:[eE][-+]?\d*)?)|'''
      r'''\b(abstract|as|assert|break|case|catch|class|const|continue|default|do|else|enum|extends|false|final|'''
      r'''finally|for|if|implements|import|in|is|new|null|operator|part|rethrow|return|static|super|switch|this|'''
      r'''throw|true|try|typedef|var|void|while|with)\b''';
  return source.replaceAllMapped(new RegExp(RE, multiLine: true), (m) {
    if (m[1] != null) return "<span class=c>${m[1]}</span>";
    if (m[2] != null) return "<span class=l>${m[2]}</span>";
    if (m[3] != null) return "<span class=k>${m[3]}</span>";
    return m[0];
  });
}
