import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'field_order_fix.dart';

class FieldOrderRule extends DartLintRule {
  FieldOrderRule()
    : super(
        code: const LintCode(
          name: 'field_order_by_type',
          problemMessage: 'Parameters should be ordered by type',
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

      final priorities = fields.map((f) {
        final type = f.fields.type?.toSource() ?? '';
        return _priority(type);
      }).toList();

      for (var i = 1; i < priorities.length; i++) {
        if (priorities[i] < priorities[i - 1]) {
          reporter.atNode(fields[i], code);
          break;
        }
      }
    });
  }

  int _priority(String rawType) {
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
}
