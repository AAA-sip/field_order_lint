import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'utils.dart';

class ParameterOrderFix extends DartFix {
  final LintSettings settings;

  ParameterOrderFix(this.settings);

  String get name => 'Sort named parameters';

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

    final parameterList = node.thisOrAncestorOfType<FormalParameterList>();
    if (parameterList == null) return;

    final parameters = parameterList.parameters;
    final namedParameters = parameters.where((p) => p.isNamed).toList();
    if (namedParameters.length < 2) return;

    final sortedNamed = [...namedParameters]
      ..sort((a, b) {
        final groupA = getParameterGroup(a);
        final groupB = getParameterGroup(b);
        if (groupA != groupB) return groupA.compareTo(groupB);

        final typeA = _getType(a);
        final typeB = _getType(b);
        final prioA = settings.getPriority(typeA);
        final prioB = settings.getPriority(typeB);

        if (prioA != prioB) return prioA.compareTo(prioB);

        final nameA = a.name?.lexeme ?? '';
        final nameB = b.name?.lexeme ?? '';
        return nameA.compareTo(nameB);
      });

    reporter.createChangeBuilder(message: name, priority: 1).addDartFileEdit((
      builder,
    ) {
      for (var i = 0; i < namedParameters.length; i++) {
        builder.addReplacement(
          SourceRange(namedParameters[i].offset, namedParameters[i].length),
          (b) => b.write(sortedNamed[i].toSource()),
        );
      }
    });
  }

  AstNode? _findNode(CompilationUnit unit, int offset) {
    // Simple search for the parameter at offset
    for (final decl in unit.declarations) {
      if (decl is ClassDeclaration) {
        for (final member in decl.members) {
          if (member is MethodDeclaration) {
            for (final p
                in member.parameters?.parameters ?? <FormalParameter>[]) {
              if (p.offset == offset) return p;
            }
          }
          if (member is ConstructorDeclaration) {
            for (final p in member.parameters.parameters) {
              if (p.offset == offset) return p;
            }
          }
        }
      } else if (decl is FunctionDeclaration) {
        for (final p
            in decl.functionExpression.parameters?.parameters ??
                <FormalParameter>[]) {
          if (p.offset == offset) return p;
        }
      }
    }
    return null;
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
