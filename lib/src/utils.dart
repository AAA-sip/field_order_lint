
import 'package:analyzer/dart/ast/ast.dart';

int getModifierPriority(FieldDeclaration node) {
  final v = node.fields;
  if (node.isStatic) return 0;
  if (v.isLate) return 3;
  if (v.isFinal) return 1;
  return 2;
}

bool _isCollection(String type) {
  return type.startsWith('List') ||
      type.startsWith('Map') ||
      type.startsWith('Set') ||
      type.startsWith('Iterable');
}

int _getTypeGroup(String type) {
  if (['int', 'double', 'bool', 'num'].contains(type)) return 0;
  if (type == 'String') return 1;
  return 2;
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

int getPriority(String rawType) {
  final nullable = rawType.endsWith('?');
  final cleanType =
      nullable ? rawType.substring(0, rawType.length - 1) : rawType;

  if (_isCollection(cleanType)) {
    final innerType = _getInnerType(cleanType);
    final group = _getTypeGroup(innerType);
    // 6, 7, 8 for Non-Nullable Collections
    // 9, 10, 11 for Nullable Collections
    int base = nullable ? 9 : 6;
    return base + group;
  }

  final group = _getTypeGroup(cleanType);
  // 0, 1, 2 for Non-Nullable
  // 3, 4, 5 for Nullable
  int base = nullable ? 3 : 0;
  return base + group;
}
