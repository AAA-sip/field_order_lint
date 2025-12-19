library field_order_lints;

import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'src/constructor_order_rule.dart';
import 'src/field_order_rule.dart';
import 'src/field_separator_rule.dart';
import 'src/parameter_order_rule.dart';
import 'src/utils.dart';

PluginBase createPlugin() => _Plugin();

class _Plugin extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) {
    final settings = LintSettings.fromConfigs(configs);

    return [
      FieldOrderRule(settings),
      ConstructorOrderRule(),
      FieldSeparatorRule(settings),
      ParameterOrderRule(settings),
    ];
  }
}
