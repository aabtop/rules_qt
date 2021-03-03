load("@com_github_zaucy_rules_7zip//:setup.bzl", "setup_7zip")
load("@com_github_zaucy_rules_vulkan//:repo.bzl", "vulkan_repos")
load("@os_specific_vulkan_sdk_rules//:current_os_repo.bzl", "setup_os_specific_vulkan_repos")
load("@aabtop_rules_qt//:qt_repository_rules.bzl", "fetch_and_build_qt", "qt_bin")

def rules_qt_deps2(local_build="prebuilt"):
  setup_7zip()
  vulkan_repos()

  setup_os_specific_vulkan_repos()

  fetch_and_build_qt(name="aabtop_qt_build")

  qt_bin(
      name="aabtop_qt_bin",
      local_build=local_build,
  )