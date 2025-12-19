import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'constructor_order_fix.dart';

class ConstructorOrderRule extends DartLintRule {
  ConstructorOrderRule()
      : super(
          code: const LintCode(
            name: 'constructor_order_by_field',
            problemMessage:
                'Constructor parameters should be ordered by field order',
          ),
        );

  @override
  List<DartFix> getFixes() => [ConstructorOrderFix()];

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addConstructorDeclaration((node) {
      final classDecl = node.parent;
      if (classDecl is! ClassDeclaration) return;

      final fields = classDecl.members
          .whereType<FieldDeclaration>()
          .expand((f) => f.fields.variables)
          .toList();

      final fieldIndexMap = {
        for (var i = 0; i < fields.length; i++) fields[i].name.lexeme: i
      };

      final parameters = node.parameters.parameters;
      final namedParameters = parameters.where((p) => p.isNamed).toList();

      int lastIndex = -1;

      for (final param in namedParameters) {
        final name = param.name?.lexeme;
        if (name == null) continue;

        final index = fieldIndexMap[name];
        if (index == null) continue; // Skip non-field params

        if (index < lastIndex) {
          reporter.atNode(param, code);
          break;
        }
        lastIndex = index;
      }
    });
  }
}
