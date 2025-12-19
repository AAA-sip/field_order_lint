# 🎯 Field Order Lint

A Dart custom linter that automatically organizes class fields in a consistent, readable order.

## 📦 Installation

Add to your `pubspec.yaml`:

```yaml

dev_dependencies:
  custom_lint: (^0.8.1) || any?
  field_order_lints:
    git:
      url: https://github.com/AAA-sip/field_order_lint.git
      ref: main
```

of course Than in `analysis_options.yaml`

```yaml
analyzer:
  plugins:
    - custom_lint

custom_lint:
  rules:
    - field_order_by_type
    - constructor_order_by_field
    - field_separator_between_groups
    - parameter_order_by_type
```

## ✨ What it does

The linter enforces a clean field ordering convention in your Dart classes:

1. **Non-nullable primitives** (`int`, `String`, `bool`, etc.)
2. **Non-nullable objects** (custom classes)
3. **Nullable primitives** (`int?`, `String?`, `bool?`, etc.)
4. **Non-nullable collections** (`List<T>`, `Map<K,V>`, `Set<T>`)
5. **Nullable collections** (`List<T>?`, `Map<K,V>?`, `Set<T>?`)
6. **Nullable objects with nullable generics** (`List<T?>`, `List<T?>?`)

## 📝 Example

### Before

```dart
class AggregationEntity {
  final List<String> codes;
  final int createdBy;
  final int itemsCount;
  final List<Lox>? newt;
  final String? comment;
  final Lox da;
  final String id;
  final List<Lox?>? nwewt;
  final List<Lox?> net;
}
```

### After

```dart
class AggregationEntity {
  final int createdBy;
  final int itemsCount;
  final String id;
  final Lox da;
  final String? comment;
  final List<String> codes;
  final List<Lox>? newt;
  final List<Lox?>? nwewt;
  final List<Lox?> net;
}
```

## 🚀 Future Plans

- Support for `required` fields
- Support for `this.field` constructor parameters
- Customizable ordering rules
- For functions ()?
- And more...
- Six para


## 📄 License

MIT?
