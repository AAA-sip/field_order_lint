import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class FieldOrderFix extends DartFix {
  String get name => 'Sort fields by types';

  @override
  Future<void> run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    Diagnostic error,
    List<Diagnostic> others,
  ) async {
    final result = await resolver.getResolvedUnitResult();

    final unit = result.unit;
    final node = _findNode(unit, error.offset);
    if (node == null) return;

    final classDecl = node.thisOrAncestorOfType<ClassDeclaration>();
    if (classDecl == null) return;

    final fields = classDecl.members.whereType<FieldDeclaration>().toList();

    final List<FieldDeclaration> sorted = [...fields]
      ..sort((a, b) {
        return _priority(a).compareTo(_priority(b));
      });

    if (_sameOrder(fields, sorted)) return;

    reporter.createChangeBuilder(message: name, priority: 1).addDartFileEdit((
      builder,
    ) {
      for (var i = 0; i < fields.length; i++) {
        builder.addReplacement(
          SourceRange(fields[i].offset, fields[i].length),
          (b) => b.write(sorted[i].toSource()),
        );
      }
    });
  }

  FieldDeclaration? _findNode(CompilationUnit unit, int offset) {
    for (final decl in unit.declarations) {
      if (decl is ClassDeclaration) {
        for (final member in decl.members) {
          if (member is FieldDeclaration && member.offset == offset) {
            return member;
          }
        }
      }
    }
    return null;
  }

  int _priority(FieldDeclaration f) {
    final rawType = f.fields.type?.toSource() ?? '';
    final nullable = rawType.endsWith('?');
    final type = nullable ? rawType.substring(0, rawType.length - 1) : rawType;

    if (type.startsWith('List') ||
        type.startsWith('Map') ||
        type.startsWith('Set') ||
        type.startsWith('Iterable')) {
      return 4;
    }

    if (nullable) return 3;

    if (['int', 'double', 'bool', 'num'].contains(type)) return 0;
    if (type == 'String') return 1;

    return 2;
  }

  bool _sameOrder(List<FieldDeclaration> a, List<FieldDeclaration> b) {
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
