# Bazel Qt Build Rules

This repository contains Bazel rules for building Qt.  Additionally, it also
provides as releases pre-built open source versions of Qt with Bazel BUILD
files included.

To use it, add:

```python
http_archive(
    name = "aabtop_rules_qt",
    strip_prefix = "rules_qt-4703da94a8a996e9372e6ec3d33bb082a2882e8d",
    url = "https://github.com/aabtop/rules_qt/archive/4703da94a8a996e9372e6ec3d33bb082a2882e8d.zip",
    sha256 = "ba7912fe87a6a389bb83f83baa1d89d9f899abf1739b3aaf972169d934da6c9b",
)
)

load("@aabtop_rules_qt//:rules_qt_deps1.bzl", "rules_qt_deps1")
rules_qt_deps1()
load("@aabtop_rules_qt//:rules_qt_deps2.bzl", "rules_qt_deps2")
rules_qt_deps2()
```

to your `WORKSPACE` file. Note that by default, it will reference pre-built
Qt binaries stored as a GitHub release for this repository. If you would like
to build Qt from source, modify the last line above from `rules_qt_deps2()` to
`rules_qt_deps2("local")`, and be prepared to wait a couple of hours.


The rules can be accessed by loading:

```python
load("@aabtop_rules_qt//:qt_rules.bzl", "qt_cc_library", "qt_cc_binary", "qt_resource")
```

See the [//sample/BUILD](sample/BUILD) file for example usage.


## Rebuilding the binary releases

In order to rebuild the binary versions of Qt referenced in the releases,
run `./build.sh out` on Linux and `./build.bat out`
on Windows. Note that both of those commands require Docker (or Docker Desktop
for Windows, in Windows mode) to be installed. You will then find the output
archive in the `out/` folder, which can then be manually uploaded to GitHub as a
release. Afterwards, the references to `aabtop_qt_bin_linux` and
`aabtop_qt_bin_windows` should be updated in
[rules_qt_deps1.bzl](rules_qt_deps1.bzl).

Finally, after the change above to update the releases is merged, the
instructions in this README file above should be updated to point to the
new commit hash which references the updated release archives.
