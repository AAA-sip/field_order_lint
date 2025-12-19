import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class FieldSeparatorFix extends DartFix {
  String get name => 'Add blank line';

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

    reporter.createChangeBuilder(message: name, priority: 1).addDartFileEdit((
      builder,
    ) {
      builder.addInsertion(node.offset, (b) => b.writeln());
    });
  }

  AstNode? _findNode(CompilationUnit unit, int offset) {
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
}
