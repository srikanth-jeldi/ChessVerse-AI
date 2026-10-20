import 'dart:convert';
import 'dart:io';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'audit_ui.dart' show visible;

// Only app-authored literal copy: never infer templates from user/server data.
class DynamicCopy extends RecursiveAstVisitor<void> {
  final edits = <int, (int, String)>{};
  bool literalBranches(Expression e) {
    if (e is SimpleStringLiteral) return true;
    if (e is ConditionalExpression) {
      return literalBranches(e.thenExpression) && literalBranches(e.elseExpression);
    }
    return false;
  }
  void check(int offset, int length, ArgumentList args) {
    if (args.arguments.isEmpty) return;
    final first = args.arguments.first;
    if (first is StringInterpolation) {
      var template = '';
      final values = <String>[];
      for (final element in first.elements) {
        if (element is InterpolationString) template += element.value;
        if (element is InterpolationExpression) {
          template += '{${values.length}}';
          values.add(element.expression.toSource());
        }
      }
      if (!visible(template)) return;
      edits[offset] = (length, 'UiText');
      edits[first.offset] = (first.length,
          '${jsonEncode(template).replaceAll(r'$', r'\$')}, values: [${values.join(', ')}]');
    } else if (first is ConditionalExpression && literalBranches(first)) {
      edits[offset] = (length, 'UiText');
    }
  }
  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == 'Text' && node.target == null) {
      check(node.methodName.offset, node.methodName.length, node.argumentList);
    }
    super.visitMethodInvocation(node);
  }
}

void main() {
  var count = 0;
  for (final file in Directory('E:/ChessVerse-AI/mobile/lib').listSync(recursive:true).whereType<File>()) {
    final path = file.path.replaceAll('\\','/');
    if (!path.endsWith('.dart') || !(path.contains('/presentation/') ||
        path.contains('/core/widgets/') || path.contains('/main_parts/') || path.endsWith('/main.dart'))) continue;
    var source = file.readAsStringSync();
    final unit = parseString(content:source, throwIfDiagnostics:false).unit;
    final visitor = DynamicCopy();
    unit.accept(visitor);
    if (visitor.edits.isEmpty) continue;
    for (final offset in visitor.edits.keys.toList()..sort((a,b)=>b.compareTo(a))) {
      final edit = visitor.edits[offset]!;
      source = source.replaceRange(offset, offset+edit.$1, edit.$2);
    }
    if (!unit.directives.any((d)=>d is PartOfDirective) &&
        !source.contains("import 'package:chessverse_ai/core/app_ui_localizations.dart'")) {
      source = "import 'package:chessverse_ai/core/app_ui_localizations.dart';\n$source";
    }
    file.writeAsStringSync(source);
    count += visitor.edits.length;
  }
  stdout.writeln('$count dynamic copy edits');
}
