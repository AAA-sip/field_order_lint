import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class ConstructorOrderFix extends DartFix {
  String get name => 'Sort constructor parameters by field order';

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

    final constructor = node.thisOrAncestorOfType<ConstructorDeclaration>();
    if (constructor == null) return;

    final classDecl = constructor.parent;
    if (classDecl is! ClassDeclaration) return;

    // Get all fields in order
    final fields = classDecl.members
        .whereType<FieldDeclaration>()
        .expand((f) => f.fields.variables)
        .toList();

    final fieldIndexMap = {
      for (var i = 0; i < fields.length; i++) fields[i].name.lexeme: i
    };

    final parameters = constructor.parameters.parameters;
    final namedParameters = parameters.where((p) => p.isNamed).toList();
    if (namedParameters.isEmpty) return;

    final sortedNamed = [...namedParameters]..sort((a, b) {
        final nameA = a.name?.lexeme ?? '';
        final nameB = b.name?.lexeme ?? '';
        final indexA = fieldIndexMap[nameA];
        final indexB = fieldIndexMap[nameB];

        if (indexA != null && indexB != null) {
          return indexA.compareTo(indexB);
        }
        if (indexA != null) return -1; // Field-params before others
        if (indexB != null) return 1;
        return 0; // Keep relative order for non-fields
      });

    // Check if already sorted
    bool sorted = true;
    for (var i = 0; i < namedParameters.length; i++) {
      if (namedParameters[i] != sortedNamed[i]) {
        sorted = false;
        break;
      }
    }
    if (sorted) return;

    reporter.createChangeBuilder(message: name, priority: 1).addDartFileEdit((
      builder,
    ) {
      for (var i = 0; i < namedParameters.length; i++) {
        final oldParam = namedParameters[i];
        final newParam = sortedNamed[i];
        
        // We replace each parameter slot with the new parameter's source
        builder.addReplacement(
          SourceRange(oldParam.offset, oldParam.length),
          (b) => b.write(newParam.toSource()),
        );
      }
    });
  }

  AstNode? _findNode(CompilationUnit unit, int offset) {
    for (final decl in unit.declarations) {
      if (decl is ClassDeclaration) {
        for (final member in decl.members) {
          if (member is ConstructorDeclaration) {
             for (final param in member.parameters.parameters) {
                 if (param.offset == offset) return param;
             }
             // Also check the constructor name or body if needed, 
             // but usually the error is on the parameter.
             if (member.offset <= offset && member.end >= offset) {
                 return member;
             }
          }
        }
      }
    }
    return null;
  }
}
