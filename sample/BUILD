load("//:qt_rules.bzl", "qt_cc_library", "qt_cc_binary", "qt_resource")

qt_cc_binary(
  name = "sample",
  srcs = [
    "main.cc",
  ],
  deps = [
    ":main_window",
  ],
  qt_dep = "@qt//:qt",
)

qt_cc_library(
  name = "main_window",
  srcs = [
    "main_window.cc",
  ],
  hdr = "main_window.h",
  ui_src = "main_window.ui",
  qt_dep = "@qt//:qt",
)
