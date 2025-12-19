
import 'package:analyzer/dart/ast/ast.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class LintSettings {
  final Map<String, int> typeToGroup;
  final int otherGroupIndex;
  final List<int> modifierPriority; // index 0: static, 1: final, 2: mutable, 3: late

  LintSettings({
    required this.typeToGroup,
    required this.otherGroupIndex,
    required this.modifierPriority,
  });

  factory LintSettings.fromConfigs(CustomLintConfigs configs) {
    final options = configs.rules['field_order_by_type']?.json ??
        configs.rules['parameter_order_by_type']?.json ??
        {};

    Map<String, int> typeToGroup = {
      'int': 0,
      'double': 0,
      'bool': 0,
      'num': 0,
      'String': 1,
    };
    int otherGroupIndex = 2;

    final customTypePriority = options['type_priority'];
    if (customTypePriority is List) {
      typeToGroup = {};
      for (var i = 0; i < customTypePriority.length; i++) {
        final item = customTypePriority[i];
        if (item is String) {
          typeToGroup[item] = i;
        } else if (item is List) {
          for (final type in item) {
            if (type is String) typeToGroup[type] = i;
          }
        }
      }
      otherGroupIndex = customTypePriority.length;
    }

    List<int> modifierPriority = [0, 1, 2, 3];
    final customModPriority = options['modifier_priority'];
    if (customModPriority is List) {
      // Map names like 'static', 'final', 'mutable', 'late' to indices 0, 1, 2, 3
      final nameToIndex = {
        'static': 0,
        'final': 1,
        'mutable': 2,
        'late': 3,
      };
      modifierPriority = List.filled(4, 4); // Default to last if not mentioned
      for (var i = 0; i < customModPriority.length; i++) {
        final name = customModPriority[i];
        final idx = nameToIndex[name];
        if (idx != null) {
          modifierPriority[idx] = i;
        }
      }
    }

    return LintSettings(
      typeToGroup: typeToGroup,
      otherGroupIndex: otherGroupIndex,
      modifierPriority: modifierPriority,
    );
  }

  int getModifierPriority(FieldDeclaration node) {
    final v = node.fields;
    int idx;
    if (node.isStatic) {
      idx = 0;
    } else if (v.isLate) {
      idx = 3;
    } else if (v.isFinal) {
      idx = 1;
    } else {
      idx = 2;
    }
    return modifierPriority[idx];
  }

  int getTypeGroup(String type) {
    return typeToGroup[type] ?? otherGroupIndex;
  }

  int getPriority(String rawType) {
    final nullable = rawType.endsWith('?');
    final cleanType =
        nullable ? rawType.substring(0, rawType.length - 1) : rawType;

    final groupsCount = otherGroupIndex + 1;

    if (_isCollection(cleanType)) {
      final innerType = _getInnerType(cleanType);
      final group = getTypeGroup(innerType);
      // Non-Nullable Collections: 2 * groupsCount to 3 * groupsCount - 1
      // Nullable Collections: 3 * groupsCount to 4 * groupsCount - 1
      int base = nullable ? 3 * groupsCount : 2 * groupsCount;
      return base + group;
    }

    final group = getTypeGroup(cleanType);
    // Non-Nullable: 0 to groupsCount - 1
    // Nullable: groupsCount to 2 * groupsCount - 1
    int base = nullable ? groupsCount : 0;
    return base + group;
  }
}

int getParameterGroup(FormalParameter p) {
  if (p is DefaultFormalParameter) {
    return p.isRequired ? 0 : 1;
  }
  return 0;
}

bool _isCollection(String type) {
  return type.startsWith('List') ||
      type.startsWith('Map') ||
      type.startsWith('Set') ||
      type.startsWith('Iterable');
}

String _getInnerType(String type) {
  if (!type.contains('<')) return 'dynamic';
  final startIndex = type.indexOf('<') + 1;
  final endIndex = type.lastIndexOf('>');
  if (startIndex <= 0 || endIndex <= 0) return 'dynamic';
  final content = type.substring(startIndex, endIndex);
  var inner = content.split(',')[0].trim();
  if (inner.endsWith('?')) {
    inner = inner.substring(0, inner.length - 1);
  }
  return inner;
}
