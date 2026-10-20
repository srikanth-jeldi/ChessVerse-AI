import 'dart:convert';
import 'dart:io';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

// Parser-based inventory; no source code or account data is sent to translators.
String normalize(String value) => value.replaceAll(RegExp(r'\s+'), ' ').trim();
bool visible(String value) {
  final s = normalize(value);
  return s.isNotEmpty &&
      RegExp(r'[A-Za-z]{2}').hasMatch(s) &&
      !RegExp(r'https?://|assets/|^\w+@\w+|^[a-h][1-8][a-h][1-8]$').hasMatch(s) &&
      !{'ChessVerseAI', 'Google', 'Facebook', 'PGN', 'FEN', 'ELO', 'XP'}.contains(s);
}

class Audit extends RecursiveAstVisitor<void> {
  Audit(this.path, this.source);
  final String path, source;
  final entries = <Map<String, Object>>[];
  final seen = <int>{};
  final dynamicText = <String>[];
  void add(Expression expression, String kind) {
    if (expression is ConditionalExpression) {
      add(expression.thenExpression, kind);
      add(expression.elseExpression, kind);
      return;
    }
    String? value;
    if (expression is StringLiteral) value = expression.stringValue;
    if (value == null || !visible(value) || !seen.add(expression.offset)) return;
    entries.add({
      'file': path,
      'offset': expression.offset,
      'length': expression.length,
      'kind': kind,
      'source': normalize(value),
    });
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final type = node.constructorName.type.name.lexeme;
    if ((type == 'Text' || type == 'UiText') && node.constructorName.name == null &&
        node.argumentList.arguments.isNotEmpty) {
      add(node.argumentList.arguments.first, 'Text');
      if (node.argumentList.arguments.first is! StringLiteral) {
        dynamicText.add('$path:${source.substring(0, node.offset).split('\n').length}: ${node.argumentList.arguments.first.toSource()}');
      }
    }
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if ({'Text', 'UiText'}.contains(node.methodName.name) &&
        node.argumentList.arguments.isNotEmpty) {
      add(node.argumentList.arguments.first, 'Text');
      if (node.argumentList.arguments.first.stringValueOrNull == null) {
        dynamicText.add('$path:${source.substring(0, node.offset).split('\n').length}: ${node.argumentList.arguments.first.toSource()}');
      }
    }
    if (node.methodName.name == 'uiText' && node.argumentList.arguments.length == 2) {
      add(node.argumentList.arguments[1], 'uiText');
    }
    super.visitMethodInvocation(node);
  }

  @override
  void visitNamedExpression(NamedExpression node) {
    final name = node.name.label.name;
    if ({
      'labelText', 'hintText', 'helperText', 'errorText', 'tooltip',
      'title', 'subtitle', 'label', 'message', 'text', 'semanticsLabel', 'eyebrow', 'body',
    }.contains(name)) {
      add(node.expression, name);
    }
    super.visitNamedExpression(node);
  }
}

extension on Expression {
  String? get stringValueOrNull => this is StringLiteral
      ? (this as StringLiteral).stringValue : null;
}

void main(List<String> args) {
  final root = Directory('E:/ChessVerse-AI/mobile/lib');
  final entries = <Map<String, Object>>[];
  final dynamicText = <String>[];
  for (final file in root.listSync(recursive: true).whereType<File>()) {
    final path = file.path.replaceAll('\\', '/');
    if (!path.endsWith('.dart') ||
        !(path.contains('/presentation/') || path.contains('/core/widgets/') ||
          path.contains('/main_parts/') || path.endsWith('/main.dart'))) continue;
    final source = file.readAsStringSync();
    final audit = Audit(path, source);
    parseString(content: source, throwIfDiagnostics: false).unit.accept(audit);
    entries.addAll(audit.entries);
    dynamicText.addAll(audit.dynamicText);
  }
  final phrases = entries.map((e) => e['source'] as String).toSet().toList()..sort();
  File('E:/ChessVerse-AI/.build-tmp/ui-copy-audit.json')
      .writeAsStringSync(const JsonEncoder.withIndent('  ').convert(entries));
  File('E:/ChessVerse-AI/.build-tmp/ui-copy-source.json')
      .writeAsStringSync(const JsonEncoder.withIndent('  ').convert(phrases));
  File('E:/ChessVerse-AI/.build-tmp/ui-dynamic-text.txt')
      .writeAsStringSync(dynamicText.join('\n'));
  stdout.writeln('${entries.length} occurrences; ${phrases.length} phrases');
}
