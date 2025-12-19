dart linter for field_order in class

(maybe in future
1. required, this.type fields
2. in function fields
)

pubspec.yaml:

dependencies:
  custom_lint_builder: (^0.8.1)

dev_dependencies:
  custom_lint: (^0.8.1)
  field_order_lints:
    git:
      url: https://github.com/AAA-sip/field_order_lint.git
      ref: main
