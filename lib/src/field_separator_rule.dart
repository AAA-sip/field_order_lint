import 'package:analyzer/dart/ast/ast.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:analyzer/error/listener.dart';

import 'field_separator_fix.dart';
import 'utils.dart';

class FieldSeparatorRule extends DartLintRule {
  FieldSeparatorRule()
      : super(
          code: const LintCode(
            name: 'field_separator_between_groups',
            problemMessage: 'Field groups should be separated by a blank line',
          ),
        );

  @override
  List<DartFix> getFixes() => [FieldSeparatorFix()];

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addClassDeclaration((node) {
      final fields = node.members.whereType<FieldDeclaration>().toList();
      if (fields.isEmpty) return;

      for (var i = 1; i < fields.length; i++) {
        final prev = fields[i - 1];
        final curr = fields[i];

        final prevGroup = getModifierPriority(prev);
        final currGroup = getModifierPriority(curr);

        if (prevGroup != currGroup) {
          // Check for blank line
          // We can read the source from the resolver, but here we don't have direct access to source text easily
          // without using `resolver.getResolvedUnitResult` which is async, but `run` is sync.
          // However, `node.root` or similar might give access.
          // `node` is `ClassDeclaration`, it has `root`? No.
          // But `LintRule` usually works on AST.
          // We can use `curr.beginToken.precedingComments`?
          // Or check the token stream.
          
          final prevEnd = prev.end;
          final currStart = curr.offset;
          
          // Using lineInfo from the compilation unit
          final unit = node.thisOrAncestorOfType<CompilationUnit>();
          final lineInfo = unit?.lineInfo;
          if (lineInfo == null) continue;

          final prevLine = lineInfo.getLocation(prevEnd).lineNumber;
          final currLine = lineInfo.getLocation(currStart).lineNumber;

          // If simple declared:
          // int a; (line 1)
          // int b; (line 2) -> diff 1.
          // int a; (line 1)
          //        (line 2)
          // int b; (line 3) -> diff 2.
          
          // However, this ignores comments in between.
          // int a;
          // // comment
          // int b;
          // The comment is part of the "gap".
          // If the comment belongs to `b`, `currStart` usually includes it if it is a doc comment.
          // But regular comments are ignored in AST node range usually?
          // Actually, `FieldDeclaration` documentation comment IS part of the node.
          // Preceding regular comments are NOT.
          
          // Let's assume we want a VISUAL blank line.
          // If there is a comment, we want a blank line before the comment?
          // Or a blank line between `prev` and `curr` (including its comments).
          
          // Simplest check: Line difference > 1 + (number of comment lines?)
          // This is getting complicated.
          
          // Alternative: Check the source string.
          // But we don't have source string here easily?
          // `node.root` -> `CompilationUnit`. 
          // `unit.toSource()`? No, that's slow.
          // `unit.lineInfo` gives lines.
          
          if (currLine - prevLine < 2) {
             reporter.atNode(curr, code);
          }
        }
      }
    });
  }
}
