# Bazel Qt Build Rules

This repository contains Bazel rules for building Qt.  Additionally, it also
provides as releases pre-built open source versions of Qt with Bazel BUILD
files included.

To use it, add:

```python
http_archive(
    name = "aabtop_rules_qt",
    strip_prefix = "rules_qt-????",
    url = "https://github.com/aabtop/rules_qt/archive/?????.zip",
    sha256 = "?????",
)


load("@aabtop_rules_qt//:rules_qt_deps1.bzl", "rules_qt_deps1")
rules_qt_deps1()
load("@aabtop_rules_qt//:rules_qt_deps2.bzl", "rules_qt_deps2")
rules_qt_deps2()
```

to your `WORKSPACE` file.

The rules can be accessed by loading:

```python
load("@aabtop_rules_qt//:qt_rules.bzl", "qt_cc_library", "qt_cc_binary", "qt_resource")
```

See the [//sample/BUILD](sample/BUILD) file for example usage.
