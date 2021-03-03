load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:git.bzl", "git_repository")
load("@aabtop_rules_qt//:qt_repository_rules.bzl", "setup_qt_dependencies")

def rules_qt_deps1():
  setup_qt_dependencies()

  http_archive(
      name = "com_github_zaucy_rules_7zip",
      strip_prefix = "rules_7zip-e95ba876db445cf2c925c02c4bc18ed37a503fd8",
      url = "https://github.com/zaucy/rules_7zip/archive/e95ba876db445cf2c925c02c4bc18ed37a503fd8.zip",
      sha256 = "b66e1c712577b0c029d4c94228dba9c8aacdcdeb88c3b1eeeffd00247ba5a856",
  )

  git_repository(
      name = "com_github_zaucy_rules_vulkan",
      remote = "https://github.com/zaucy/rules_vulkan",
      commit = "ebfb9377f616cf12ffe0a9e1088ca0c005bd2db4",
      shallow_since = "1611480038 +0000",
  )
