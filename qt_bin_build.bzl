load("{QT_BIN_REPO}//:components.bzl", "QT_COMPONENTS")


def with_bin_repo_prefix(x):
    return "{QT_BIN_REPO}//:" + x

def in_bin_repo(l):
    return [with_bin_repo_prefix(x) for x in l]

def linux_interface_lib_filename_for_module(x):
    return "lib/{}".format(linux_interface_lib_target_for_module(x))
def linux_shared_lib_filename_for_module(x):
    return "lib/{}.5".format(linux_interface_lib_target_for_module(x))
def linux_interface_lib_target_for_module(x):
    return "lib{}.so".format(x)

def qt_bin_build():
    qt_modules = ["Qt5{}".format(x) for x in QT_COMPONENTS]
    win_qt_modules = [
        "libEGL",
        "libGLESv2",
    ] + qt_modules
    linux_qt_modules = ["Qt5XcbQpa"] + qt_modules

    win_static_library_filepaths = (
        ["lib/{}.lib".format(x) for x in win_qt_modules]
    )
    win_lib_filepaths = ["bin/{}.dll".format(x) for x in win_qt_modules]

    linux_lib_filepaths = (
        [linux_shared_lib_filename_for_module(x) for x in linux_qt_modules]
    )

    for x in linux_qt_modules:
        native.cc_import(
            name = linux_interface_lib_target_for_module(x),
            # We need to refer to the `.so` file, not the `.so.VERSION` file,
            # because otherwise Bazel will complain.
            interface_library = with_bin_repo_prefix(linux_interface_lib_filename_for_module(x)),
            # By setting system_provided = 1, it tells Bazel not to manage this
            # library at runtime. This lets us manually position the file in
            # the Qt-expected lib/ directory.
            system_provided = 1,
        )

    include_directories = ["include"] + ["include/Qt{}".format(x) for x in QT_COMPONENTS]

    resources = [
        "resources/icudtl.dat",
        "resources/qtwebengine_devtools_resources.pak",
        "resources/qtwebengine_resources.pak",
        "resources/qtwebengine_resources_100p.pak",
        "resources/qtwebengine_resources_200p.pak",
    ]

    win_plugings_platforms_files = [
        "plugins/platforms/qwindows.dll",
    ]
    linux_plugins_platforms_files = [
        #"plugins/platforms/libqeglfs.so",
        "plugins/platforms/libqxcb.so",
        #"plugins/platforms/libqlinuxfb.so",
        #"plugins/platforms/libqminimalegl.so",
        #"plugins/platforms/libqminimal.so",
        #"plugins/platforms/libqoffscreen.so",
        #"plugins/platforms/libqvnc.so",
        #"plugins/platforms/libqwebgl.so",
    ]

    translations = [
        "translations/qtwebengine_locales/en-US.pak",
    ]

    # Files which are expected to live as sibling files to the final executable.
    native.filegroup(
        name = "qt_data_files",
        srcs = in_bin_repo(resources + translations),
        visibility = ["//visibility:public"],
    )

    native.filegroup(
        name = "qt_plugins_platforms_files",
        srcs = select({
            "@bazel_tools//src/conditions:windows": in_bin_repo(win_plugings_platforms_files),
            "//conditions:default": in_bin_repo(linux_plugins_platforms_files),
        }),
        visibility = ["//visibility:public"],
    )

    native.filegroup(
        name = "qt_libexec_files",
        srcs = select({
            "@bazel_tools//src/conditions:windows": in_bin_repo(["bin/QtWebEngineProcess.exe"]),
            "//conditions:default": in_bin_repo(["libexec/QtWebEngineProcess"]),
        }),
        visibility = ["//visibility:public"],
    )

    native.filegroup(
        name = "qt_lib_files",
        srcs = select({
            "@bazel_tools//src/conditions:windows": in_bin_repo(win_lib_filepaths),
            "//conditions:default": in_bin_repo(linux_lib_filepaths),
        }),
        visibility = ["//visibility:public"],
    )

    native.cc_library(
        name = "qt_lib",
        srcs = select({
            "@bazel_tools//src/conditions:windows": in_bin_repo(win_static_library_filepaths),
            "//conditions:default": [],
        }),
        visibility = ["//visibility:public"],
        deps = [
            "@vulkan_sdk//:vulkan",
            with_bin_repo_prefix("header_files"),
        ] + select({
            "@bazel_tools//src/conditions:windows": [],
            "//conditions:default": [":{}".format(linux_interface_lib_target_for_module(x)) for x in linux_qt_modules],
        }),
    )

    native.alias(
        name = "moc",
        actual = select({
            "@bazel_tools//src/conditions:windows": with_bin_repo_prefix("bin/moc.exe"),
            "//conditions:default": with_bin_repo_prefix("bin/moc"),
        }),
        visibility = ["//visibility:public"],
    )
    native.alias(
        name = "uic",
        actual = select({
            "@bazel_tools//src/conditions:windows": with_bin_repo_prefix("bin/uic.exe"),
            "//conditions:default": with_bin_repo_prefix("bin/uic"),
        }),
        visibility = ["//visibility:public"],
    )
    native.alias(
        name = "rcc",
        actual = select({
            "@bazel_tools//src/conditions:windows": with_bin_repo_prefix("bin/rcc.exe"),
            "//conditions:default": with_bin_repo_prefix("bin/rcc"),
        }),
        visibility = ["//visibility:public"],
    )
