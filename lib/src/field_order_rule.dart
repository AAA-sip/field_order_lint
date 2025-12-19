import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'field_order_fix.dart';
import 'utils.dart';

class FieldOrderRule extends DartLintRule {
  FieldOrderRule()
      : super(
          code: const LintCode(
            name: 'field_order_by_type',
            problemMessage: 'Fields should be ordered by type and name',
          ),
        );

  @override
  List<DartFix> getFixes() => [FieldOrderFix()];

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addClassDeclaration((node) {
      final fields = node.members.whereType<FieldDeclaration>().toList();

      for (var i = 1; i < fields.length; i++) {
        final prev = fields[i - 1];
        final curr = fields[i];

        final prevModPrio = getModifierPriority(prev);
        final currModPrio = getModifierPriority(curr);

        if (currModPrio < prevModPrio) {
          reporter.atNode(curr, code);
          break;
        }

        if (currModPrio > prevModPrio) continue;

        final prevType = prev.fields.type?.toSource() ?? '';
        final currType = curr.fields.type?.toSource() ?? '';

        final prevPrio = getPriority(prevType);
        final currPrio = getPriority(currType);

        if (currPrio < prevPrio) {
          reporter.atNode(curr, code);
          break;
        } else if (currPrio == prevPrio) {
          final prevName = prev.fields.variables.first.name.lexeme;
          final currName = curr.fields.variables.first.name.lexeme;
          if (currName.compareTo(prevName) < 0) {
            reporter.atNode(curr, code);
            break;
          }
        }
      }
    });
  }
}
