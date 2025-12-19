import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'utils.dart';

class FieldOrderFix extends DartFix {
  final LintSettings settings;

  FieldOrderFix(this.settings);

  String get name => 'Sort fields by types and name';

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
        final modPrioA = settings.getModifierPriority(a);
        final modPrioB = settings.getModifierPriority(b);
        if (modPrioA != modPrioB) return modPrioA.compareTo(modPrioB);

        final typeA = a.fields.type?.toSource() ?? '';
        final typeB = b.fields.type?.toSource() ?? '';
        final prioA = settings.getPriority(typeA);
        final prioB = settings.getPriority(typeB);

        final compare = prioA.compareTo(prioB);
        if (compare != 0) return compare;

        final nameA = a.fields.variables.first.name.lexeme;
        final nameB = b.fields.variables.first.name.lexeme;
        return nameA.compareTo(nameB);
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

  bool _sameOrder(List<FieldDeclaration> a, List<FieldDeclaration> b) {
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
