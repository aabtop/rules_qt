workspace(
    name = "com_github_aabtop_rules_qt",
)

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:git.bzl", "git_repository")

http_archive(
    name = "com_github_zaucy_rules_7zip",
    strip_prefix = "rules_7zip-e95ba876db445cf2c925c02c4bc18ed37a503fd8",
    url = "https://github.com/zaucy/rules_7zip/archive/e95ba876db445cf2c925c02c4bc18ed37a503fd8.zip",
    sha256 = "b66e1c712577b0c029d4c94228dba9c8aacdcdeb88c3b1eeeffd00247ba5a856",
)
load("@com_github_zaucy_rules_7zip//:setup.bzl", "setup_7zip")
setup_7zip()

git_repository(
    name = "com_github_zaucy_rules_vulkan",
    remote = "https://github.com/zaucy/rules_vulkan",
    commit = "ebfb9377f616cf12ffe0a9e1088ca0c005bd2db4",
    shallow_since = "1611480038 +0000",
)
load("@com_github_zaucy_rules_vulkan//:repo.bzl", "vulkan_repos")
vulkan_repos()

load("//:qt_repository_rules.bzl", "setup_qt")
setup_qt()

load("@os_specific_vulkan_sdk_rules//:current_os_repo.bzl", "setup_os_specific_vulkan_repos")
setup_os_specific_vulkan_repos()

load("@com_github_aabtop_rules_qt//:qt_repository_rules.bzl", "fetch_qt")
fetch_qt(name="qt")
