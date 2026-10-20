import 'dart:io';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'audit_ui.dart' show visible;

class Wire extends RecursiveAstVisitor<void> {
  Wire(this.source, {this.textOnly = false});
  final String source;
  final bool textOnly;
  final edits = <int, (int, String)>{};
  final skipped = <String>[];
  bool hasContext(AstNode node) {
    for (AstNode? parent = node; parent != null; parent = parent.parent) {
      if (parent is FunctionExpression &&
          (parent.parameters?.toSource().contains('context') ?? false)) return true;
      if (parent is MethodDeclaration &&
          (parent.parameters?.toSource().contains('BuildContext context') ?? false)) return true;
      if (parent is ClassDeclaration &&
          parent.extendsClause?.superclass.toSource().startsWith('State<') == true) return true;
    }
    return false;
  }
  bool canUnconst(AstNode node) {
    for (AstNode? p = node; p != null; p = p.parent) {
      if (p is DefaultFormalParameter || p is Annotation) return false;
      if (p is VariableDeclarationList && p.isConst) return false;
    }
    return true;
  }
  void unconst(AstNode node) {
    for (AstNode? p = node; p != null; p = p.parent) {
      if (p is InstanceCreationExpression && p.keyword?.lexeme == 'const') {
        edits[p.keyword!.offset] = (p.keyword!.length, '');
      } else if (p is ListLiteral && p.constKeyword != null) {
        edits[p.constKeyword!.offset] = (p.constKeyword!.length, '');
      } else if (p is SetOrMapLiteral && p.constKeyword != null) {
        edits[p.constKeyword!.offset] = (p.constKeyword!.length, '');
      }
    }
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (node.constructorName.type.name.lexeme == 'Text' &&
        node.constructorName.name == null && node.argumentList.arguments.isNotEmpty) {
      final first = node.argumentList.arguments.first;
      if (first is StringLiteral && first.stringValue != null && visible(first.stringValue!)) {
        final token = node.constructorName.type.name;
        edits[token.offset] = (token.length, 'UiText');
      }
    }
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == 'Text' && node.target == null &&
        node.argumentList.arguments.isNotEmpty) {
      final first = node.argumentList.arguments.first;
      if (first is StringLiteral && first.stringValue != null && visible(first.stringValue!)) {
        edits[node.methodName.offset] = (node.methodName.length, 'UiText');
      }
    }
    super.visitMethodInvocation(node);
  }

  @override
  void visitNamedExpression(NamedExpression node) {
    if (textOnly) return super.visitNamedExpression(node);
    final expression = node.expression;
    final owner = node.parent?.parent;
    final sourceOwner = owner?.toSource() ?? '';
    if (!sourceOwner.startsWith('TextEditingController(') && {
      'labelText', 'hintText', 'helperText', 'errorText', 'tooltip',
      'title', 'subtitle', 'label', 'message', 'text', 'semanticsLabel',
    }.contains(node.name.label.name) && expression is StringLiteral &&
        expression.stringValue != null && visible(expression.stringValue!)) {
      if (hasContext(node) && canUnconst(node)) {
        edits[expression.offset] = (expression.length, 'uiText(context, ${expression.toSource()})');
        unconst(node);
      } else {
        skipped.add('${node.name.label.name}: ${expression.toSource()}');
      }
    }
    super.visitNamedExpression(node);
  }
}

void main(List<String> args) {
  final root = Directory('E:/ChessVerse-AI/mobile/lib');
  var count = 0;
  final skipped = <String>[];
  for (final file in root.listSync(recursive: true).whereType<File>()) {
    final path = file.path.replaceAll('\\', '/');
    if (!path.endsWith('.dart') ||
        !(path.contains('/presentation/') || path.contains('/core/widgets/') ||
          path.contains('/main_parts/') || path.endsWith('/main.dart'))) continue;
    final source = file.readAsStringSync();
    final wire = Wire(source, textOnly: args.contains('--text-only'));
    final unit = parseString(content: source, throwIfDiagnostics: false).unit;
    unit.accept(wire);
    skipped.addAll(wire.skipped.map((s) => '$path: $s'));
    if (wire.edits.isEmpty) continue;
    var result = source;
    for (final offset in wire.edits.keys.toList()..sort((a, b) => b.compareTo(a))) {
      final edit = wire.edits[offset]!;
      result = result.replaceRange(offset, offset + edit.$1, edit.$2);
    }
    if (!unit.directives.any((d) => d is PartOfDirective) &&
        !source.contains("import 'package:chessverse_ai/core/app_ui_localizations.dart'")) {
      result = "import 'package:chessverse_ai/core/app_ui_localizations.dart';\n$result";
    }
    file.writeAsStringSync(result);
    count += wire.edits.length;
  }
  File('E:/ChessVerse-AI/.build-tmp/ui-copy-skipped.txt').writeAsStringSync(skipped.join('\n'));
  stdout.writeln('$count edits; ${skipped.length} explicit-context/constant cases to review');
}
