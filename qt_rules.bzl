def __qt_compile_ui_impl(ctx):
    ctx.actions.run(
        outputs = [ctx.outputs.out],
        inputs = ctx.files.ui_src,
        tools = [ctx.executable.uic],
        arguments = [ctx.files.ui_src[0].path, "-o", ctx.outputs.out.path],
        executable = ctx.executable.uic,
    )

    return DefaultInfo(files = depset([ctx.outputs.out]))

_qt_compile_ui = rule(
    implementation = __qt_compile_ui_impl,
    attrs = {
        "uic": attr.label(default = "@aabtop_qt_bin//:uic", allow_single_file = True, executable = True, cfg = "exec"),
        "ui_src": attr.label(mandatory = True, allow_single_file = True),
        "out": attr.output(mandatory = True),
    },
)

def qt_ui_header(name, ui_src):
    ui_header_file = "ui_{}.h".format(ui_src.split(".")[0])
    uic_header_target_name = "{}_uic".format(name)
    _qt_compile_ui(
        name = uic_header_target_name,
        ui_src = ui_src,
        out = ui_header_file,
    )

    native.cc_library(
        name = name,
        hdrs = [ui_header_file],
    )

def __qt_compile_moc_impl(ctx):
    ctx.actions.run(
        outputs = [ctx.outputs.out],
        inputs = ctx.files.hdr_src,
        tools = [ctx.executable.moc],
        arguments = [ctx.files.hdr_src[0].path, "-o", ctx.outputs.out.path, "-f\"{}\"".format(ctx.files.hdr_src[0].short_path)],
        executable = ctx.executable.moc,
    )

    return DefaultInfo(files = depset([ctx.outputs.out]))

_qt_compile_moc = rule(
    implementation = __qt_compile_moc_impl,
    attrs = {
        "moc": attr.label(default = "@aabtop_qt_bin//:moc", allow_single_file = True, executable = True, cfg = "exec"),
        "hdr_src": attr.label(mandatory = True, allow_single_file = True),
        "out": attr.output(mandatory = True),
        "package_name": attr.string(mandatory = True),
    },
)

def qt_moc_src(name, hdr_src):
    moc_src_file = "moc_{}.cc".format(hdr_src.split(".")[0])
    moc_target_name = "{}_moc".format(name)
    _qt_compile_moc(
        name = name,
        hdr_src = hdr_src,
        out = moc_src_file,
        package_name = native.package_name(),
    )

def qt_cc_library(name, srcs, hdr, ui_src = None, deps = [], **kwargs):
    moc_target_name = "{}_moc".format(name)
    qt_moc_src(moc_target_name, hdr)

    if ui_src:
        uic_target_name = "{}_ui".format(name)
        qt_ui_header(uic_target_name, ui_src)

    native.cc_library(
        name = name,
        srcs = srcs + [":" + moc_target_name],
        hdrs = [hdr],
        deps = ["@aabtop_qt_bin//:qt_lib"] + deps + ([":" + uic_target_name] if ui_src else []),
        **kwargs
    )

def __package_runtime_files_impl(ctx):
    local_files = []
    for x in ctx.files.runtime_files:
        new_local_file = ctx.actions.declare_file(x.path.replace(x.owner.workspace_root + "/", "qt/"))
        ctx.actions.symlink(output = new_local_file, target_file = x)
        local_files.append(new_local_file)

    for x in ctx.files.runtime_qt_libexec_files:
        new_local_file = ctx.actions.declare_file("qt/libexec/" + x.basename)
        ctx.actions.symlink(output = new_local_file, target_file = x)
        local_files.append(new_local_file)

    for x in ctx.files.runtime_qt_plugins_platforms_files:
        new_local_file = ctx.actions.declare_file("qt/plugins/platforms/" + x.basename)
        ctx.actions.symlink(output = new_local_file, target_file = x)
        local_files.append(new_local_file)

    for x in ctx.files.runtime_qt_lib_files:
        new_local_file = ctx.actions.declare_file("qt/lib/" + x.basename)
        ctx.actions.symlink(output = new_local_file, target_file = x)
        local_files.append(new_local_file)

    for x in ctx.files.runtime_qt_sibling_files:
        new_local_file = ctx.actions.declare_file(x.basename)
        ctx.actions.symlink(output = new_local_file, target_file = x)
        local_files.append(new_local_file)


    # For some reason, on Linux (but not Windows), this needs to be explicitly
    # specified.
    qt_conf_file = ctx.actions.declare_file("qt.conf")
    local_files.append(qt_conf_file)
    ctx.actions.write(output=qt_conf_file, content="""
[Paths]
Prefix = qt
    """)

    return [DefaultInfo(runfiles = ctx.runfiles(files = local_files))]

_package_runtime_files = rule(
    implementation = __package_runtime_files_impl,
    attrs = {
        "runtime_files": attr.label_list(mandatory = True),
        "runtime_qt_libexec_files": attr.label_list(mandatory = True),
        "runtime_qt_plugins_platforms_files": attr.label_list(mandatory = True),
        "runtime_qt_lib_files": attr.label_list(mandatory = True),
        "runtime_qt_sibling_files": attr.label_list(mandatory = True),
    },
)

# When going through qt_cc_binary, we ensure
def qt_cc_binary(name, srcs, deps):
    runtime_files_name = name + "_runtime_files"
    _package_runtime_files(
        name = runtime_files_name,
        runtime_files = ["@aabtop_qt_bin//:qt_data_files"],
        runtime_qt_plugins_platforms_files = ["@aabtop_qt_bin//:qt_plugins_platforms_files"],
        runtime_qt_libexec_files = select({
            "@bazel_tools//src/conditions:windows": [],
            "//conditions:default": ["@aabtop_qt_bin//:qt_libexec_files"],
        }),
        runtime_qt_lib_files = select({
            "@bazel_tools//src/conditions:windows": [],
            "//conditions:default": ["@aabtop_qt_bin//:qt_lib_files"],
        }),
        runtime_qt_sibling_files = select({
            # Windows really wants to have the DLLs live next to the executable.
            "@bazel_tools//src/conditions:windows": [
                "@aabtop_qt_bin//:qt_lib_files",
                "@aabtop_qt_bin//:qt_libexec_files"],
            "//conditions:default": [],
        }),
    )

    native.cc_binary(
        name = name,
        srcs = srcs,
        deps = ["@aabtop_qt_bin//:qt_lib"] + deps,
        data = [":" + runtime_files_name],
        linkopts = select({
            "@bazel_tools//src/conditions:windows": [],
            "//conditions:default": ["-Wl,-rpath='$$ORIGIN/qt/lib'",],
        }),
    )

def __qt_resource_impl(ctx):
    # Strip the "/BUILD", there's probably a better way but I don't know what it
    # is.
    package_dir = ctx.build_file_path[:-5]

    linked_assets = []
    workspace_relative_paths = []
    for x in ctx.files.srcs:
        workspace_relative_path = x.path
        if x.path.startswith(ctx.bin_dir.path):
            workspace_relative_path = x.path[len(ctx.bin_dir.path) + 1:]
            linked_assets.append(x)
        else:
            # The Qt rcc tool wants all the assets to be specified relative to the
            # qrc file, which we are generating.  So, symlink over all of its assets
            # so they are in trivial paths relative to the generated qrc file.
            out_path = ctx.actions.declare_file(workspace_relative_path.replace(package_dir, ""))
            ctx.actions.symlink(output = out_path, target_file = x)
            linked_assets.append(out_path)

        if workspace_relative_path.startswith('external/') and not package_dir.startswith('external/'):
            package_dir = 'external/' + package_dir

        if not workspace_relative_path.startswith(package_dir):
            fail("Resources must be relative to package. Resource: '{}', Package directory: '{}'.".format(workspace_relative_path, package_dir))

        filepath_relative_to_package_dir = workspace_relative_path[len(package_dir):]

        # If this is an external repository, clean up the external part.
        external_prefix = "external/"
        if workspace_relative_path.startswith(external_prefix):
            workspace_relative_path = workspace_relative_path[workspace_relative_path.find("/", len(external_prefix)) + 1:]

        workspace_relative_paths.append((workspace_relative_path, filepath_relative_to_package_dir))

    file_list = "\n".join([
        '<file alias="{}">{}</file>'.format(x, y) for (x,y) in workspace_relative_paths])

    qrc_content = """
        <RCC>
            <qresource prefix="{prefix}">
{file_list}
            </qresource>
        </RCC>
    """.format(prefix = ctx.attr.prefix, file_list = file_list)

    qrc_file = ctx.actions.declare_file(ctx.label.name + ".qrc")
    out_file = ctx.actions.declare_file(ctx.label.name + ".qrc.cc")

    ctx.actions.write(qrc_file, qrc_content)

    ctx.actions.run(
        outputs = [out_file],
        inputs = linked_assets + [qrc_file],
        tools = [ctx.executable.rcc],
        arguments = ["-name", ctx.label.name, "-o", out_file.path, qrc_file.path],
        executable = ctx.executable.rcc,
    )

    return DefaultInfo(files = depset([out_file]))


_qt_resource = rule(
    implementation = __qt_resource_impl,
    attrs = {
        "prefix": attr.string(mandatory = True, default = "/"),
        "srcs": attr.label_list(mandatory = True, allow_files = True),
        "rcc": attr.label(default = "@aabtop_qt_bin//:rcc", allow_single_file = True, executable = True, cfg = "exec"),
    },
)

def qt_resource(name, srcs, prefix="/"):
    cc_name = name + "_cc"
    _qt_resource(name = cc_name, srcs = srcs, prefix = prefix)
    native.cc_library(
        name = name,
        alwayslink = True,
        srcs = [":" + cc_name],
    )
