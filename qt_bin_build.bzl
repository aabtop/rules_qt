load("{QT_BIN_REPO}//:components.bzl", "QT_COMPONENTS")


def with_bin_repo_prefix(x):
    return "{QT_BIN_REPO}//:" + x


def in_bin_repo(l):
    return [with_bin_repo_prefix(x) for x in l]


def qt_bin_build():

    qt_modules = ["Qt5{}".format(x) for x in QT_COMPONENTS]
    win_qt_modules = [
        "libEGL",
        "libGLESv2",
    ] + qt_modules
    linux_qt_modules = ["Qt5XcbQpa"] + qt_modules

    win_lib_filepaths = (
        ["lib/{}.lib".format(x) for x in win_qt_modules]
    )
    linux_lib_filepaths = (
        ["lib/lib{}.so.5".format(x) for x in linux_qt_modules]
    )

    include_directories = ["include"] + ["include/Qt{}".format(x) for x in QT_COMPONENTS]

    win_shared_library_filepaths = ["bin/{}.dll".format(x) for x in win_qt_modules]
    linux_shared_library_filepaths = ["lib/lib{}.so".format(x) for x in linux_qt_modules]

    resources = [
        "resources/icudtl.dat",
        "resources/qtwebengine_devtools_resources.pak",
        "resources/qtwebengine_resources.pak",
        "resources/qtwebengine_resources_100p.pak",
        "resources/qtwebengine_resources_200p.pak",
    ]

    win_platforms_plugins = [
        "plugins/platforms/qwindows.dll",
    ]
    linux_platforms_plugins = [
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
        name = "qt_platforms_plugins",
        srcs = select({
            "@bazel_tools//src/conditions:windows": in_bin_repo(win_platforms_plugins),
            "//conditions:default": in_bin_repo(linux_platforms_plugins),
        }),
        visibility = ["//visibility:public"],
    )

    native.filegroup(
        name = "qt_data_sibling_files",
        srcs = select({
            "@bazel_tools//src/conditions:windows": in_bin_repo(["bin/QtWebEngineProcess.exe"]),
            "//conditions:default": in_bin_repo([]),
        }),
        visibility = ["//visibility:public"],
    )

    native.cc_library(
        name = "qt_lib",
        srcs = select({
            "@bazel_tools//src/conditions:windows": in_bin_repo(win_lib_filepaths + win_shared_library_filepaths),
            "//conditions:default": in_bin_repo(linux_lib_filepaths),
        }),
        visibility = ["//visibility:public"],
        deps = [
            "@vulkan_sdk//:vulkan",
            with_bin_repo_prefix("header_files"),
        ],
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
