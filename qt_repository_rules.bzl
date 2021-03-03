QT_COMPONENTS = [
    "Bodymovin",
    "Core",
    "DBus",
    "Gui",
    "Network",
    "OpenGL",
    "Pdf",
    "PrintSupport",
    "Qml",
    "QmlModels",
    "QmlWorkerScript",
    "Quick",
    "QuickShapes",
    "QuickWidgets",
    "Sql",
    "WebChannel",
    "WebEngine",
    "WebEngineCore",
    "WebEngineWidgets",
    "WebSockets",
    "Widgets",
]

def _fetch_and_build_qt_impl(repository_ctx):
    tmp_dir = "tmp"
    src_dir = tmp_dir + "/src"
    build_dir = tmp_dir + "/build"

    if "windows" in repository_ctx.os.name:
        src_url = "http://download.qt.io/official_releases/qt/5.15/5.15.2/single/qt-everywhere-src-5.15.2.zip"
        src_sha256 = "6c5d37aa96f937eb59fd4e9ce5ec97f45fbf2b5de138b086bdeff782ec661733"
    else:
        # zip vs tar is more than just cosmetic, the newlines in the configure
        # scripts have Linux formatting here and Windows above.
        src_url = "http://download.qt.io/official_releases/qt/5.15/5.15.2/single/qt-everywhere-src-5.15.2.tar.xz"
        src_sha256 = "3a530d1b243b5dec00bc54937455471aaa3e56849d2593edb8ded07228202240"

    repository_ctx.download_and_extract(
        src_url,
        stripPrefix = "qt-everywhere-src-5.15.2/",
        sha256 = src_sha256,
        output = src_dir,
    )

    env = {}
    vulkan_header_path = repository_ctx.path(repository_ctx.attr._vulkan_h)
    vulkan_dir = vulkan_header_path.dirname.dirname.dirname
    env["VULKAN_SDK"] = str(vulkan_dir)

    if "windows" in repository_ctx.os.name:
        build_script = repository_ctx.path(repository_ctx.attr._build_script_windows)
        if "BAZEL_VC" in repository_ctx.os.environ:
            env["BAZEL_VC"] = repository_ctx.os.environ["BAZEL_VC"]
            #env["ProgramFiles(x86)"] = "C:\\Program Files (x86)"
            #env["WINDIR"] = "C:\\Windows"

    else:
        build_script = repository_ctx.path(repository_ctx.attr._build_script_linux)

    repository_ctx.report_progress("Building Qt...")

    result = repository_ctx.execute(
        [build_script, src_dir, build_dir, "."],
        timeout = 140000,  # This can take a long time...
        environment = env,
        quiet = False,
    )
    if result.return_code:
        fail("Error building Qt.")

    # We clean up the checked out source code and the intermediate build files
    # so that the result that we actually cache is as small as possible.
    repository_ctx.report_progress("Deleting scratch files...")
    result = repository_ctx.delete(tmp_dir)
    if not result:
        fail("Error deleting scratch folder.")

    repository_ctx.report_progress("Creating Qt BUILD files...")
    repository_ctx.file("WORKSPACE", content = "")
    repository_ctx.file("BUILD", content = """
load("//:components.bzl", "QT_COMPONENTS")

exports_files(glob(["**"]))

cc_library(
    name = "header_files",
    hdrs = glob(["include/**"]),
    includes = ["include"] + ["include/Qt{}".format(x) for x in QT_COMPONENTS],
    visibility = ["//visibility:public"],
)
    """)
    repository_ctx.file("components.bzl", content = "QT_COMPONENTS = [{}]".format(
        ",\n".join(['"{}"'.format(x) for x in QT_COMPONENTS])))


fetch_and_build_qt = repository_rule(
    implementation = _fetch_and_build_qt_impl,
    attrs = {
        "_build_script_windows": attr.label(default = "@aabtop_rules_qt//:build_windows.bat"),
        "_build_script_linux": attr.label(default = "@aabtop_rules_qt//:build_linux.sh"),

        # We need to depend on Vulkan, but we don't know whether we're
        # downloading Windows or Linux, so unfortunately we download them both
        # because it's hard to tell Bazel to switch on OS in this context.
        "_vulkan_h": attr.label(default = "@os_specific_vulkan_sdk//:vulkan_sdk/include/vulkan/vulkan.h"),
    },
)

def __os_specific_vulkan_sdk_impl(repository_ctx):
    if "windows" in repository_ctx.os.name:
        vulkan_platform = "windows"
    else:
        vulkan_platform = "linux"

    repository_ctx.file("current_os_repo.bzl", content = """
def __sdk_symlink_impl(repository_ctx):
    vulkan_header_path = repository_ctx.path(repository_ctx.attr._vulkan_h)
    vulkan_dir = vulkan_header_path.dirname.dirname.dirname
    repository_ctx.file("BUILD", content = "")
    repository_ctx.symlink(vulkan_dir, "vulkan_sdk")

_sdk_symlink = repository_rule(
    implementation = __sdk_symlink_impl,
    attrs = {{
        "_vulkan_h": attr.label(default = "@vulkan_sdk_{}//:include/vulkan/vulkan.h"),
    }},
)


def setup_os_specific_vulkan_repos():
    _sdk_symlink(name = "os_specific_vulkan_sdk")
""".format(vulkan_platform))

    repository_ctx.file("WORKSPACE", content = "workspace(name = \"os_specific_vulkan_sdk_rules\")\n")
    repository_ctx.file("BUILD", content = "")

_os_specific_vulkan_sdk = repository_rule(
    implementation = __os_specific_vulkan_sdk_impl,
)

def setup_qt_dependencies():
    _os_specific_vulkan_sdk(name = "os_specific_vulkan_sdk_rules")


def _qt_bin_impl(repository_ctx):
    if repository_ctx.attr.local_build == "local":
        qt_bin_repo = "@aabtop_qt_build"
    else:
        if "windows" in repository_ctx.os.name:
            qt_bin_repo = "@aabtop_qt_bin_windows"
        else:
            qt_bin_repo = "@aabtop_qt_bin_linux"

    repository_ctx.template(
        "qt_bin_build.bzl", repository_ctx.attr._qt_bin_build_bzl,
        substitutions = {
            "{QT_BIN_REPO}": qt_bin_repo,
        })

    repository_ctx.file("BUILD", """
load("//:qt_bin_build.bzl", "qt_bin_build")
qt_bin_build()
    """)

qt_bin = repository_rule(
    implementation = _qt_bin_impl,
    attrs = {
        "local_build": attr.string(default = "prebuilt", values = ["local", "prebuilt"]),

        "_qt_bin_build_bzl": attr.label(default = "@aabtop_rules_qt//:qt_bin_build.bzl"),
    },
)
