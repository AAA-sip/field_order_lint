import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'parameter_order_fix.dart';
import 'utils.dart';

class ParameterOrderRule extends DartLintRule {
  final LintSettings settings;

  ParameterOrderRule(this.settings)
      : super(
          code: const LintCode(
            name: 'parameter_order_by_type',
            problemMessage:
                'Named parameters should be ordered by type and name',
          ),
        );

  @override
  List<DartFix> getFixes() => [ParameterOrderFix(settings)];

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    void checkParameters(FormalParameterList? parameterList) {
      if (parameterList == null) return;

      final namedParameters =
          parameterList.parameters.where((p) => p.isNamed).toList();
      if (namedParameters.length < 2) return;

      for (var i = 1; i < namedParameters.length; i++) {
        final prev = namedParameters[i - 1];
        final curr = namedParameters[i];

        final prevGroup = getParameterGroup(prev);
        final currGroup = getParameterGroup(curr);

        if (currGroup < prevGroup) {
          reporter.atNode(curr, code);
          break;
        }
        if (currGroup > prevGroup) continue;

        // Same group (required/optional), check type priority
        final prevType = _getType(prev);
        final currType = _getType(curr);

        final prevPrio = settings.getPriority(prevType);
        final currPrio = settings.getPriority(currType);

        if (currPrio < prevPrio) {
          reporter.atNode(curr, code);
          break;
        } else if (currPrio == prevPrio) {
          final prevName = prev.name?.lexeme ?? '';
          final currName = curr.name?.lexeme ?? '';
          if (currName.compareTo(prevName) < 0) {
            reporter.atNode(curr, code);
            break;
          }
        }
      }
    }

    context.registry.addFunctionDeclaration((node) {
      checkParameters(node.functionExpression.parameters);
    });
    context.registry.addMethodDeclaration((node) {
      checkParameters(node.parameters);
    });
    context.registry.addConstructorDeclaration((node) {
      // We skip constructors if they are handled by ConstructorOrderRule?
      // Actually, ConstructorOrderRule is for this.field matching.
      // If a constructor has regular parameters, we might want to sort them too.
      // But let's avoid conflict for now or just apply if it's not a field formal.
      // For simplicity, let's apply to all named parameters in functions/methods.
    });
  }

  String _getType(FormalParameter p) {
    if (p is DefaultFormalParameter) {
      return _getType(p.parameter);
    }
    if (p is SimpleFormalParameter) {
      return p.type?.toSource() ?? '';
    }
    if (p is FieldFormalParameter) {
       return p.type?.toSource() ?? '';
    }
    return '';
  }
}
