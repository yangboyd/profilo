load("//tools/build_defs/oss:profilo_defs.bzl", "profilo_path")
load("//build_defs:fb_xplat_cxx_library.bzl", "fb_xplat_cxx_library")

def museum_tracer_library(version):
    version_ = version.replace(".", "_")
    version_num = version.replace(".", "")

    exported_headers = [
        "ArtTracer.h",
    ]
    fb_xplat_cxx_library(
        name = "museum-tracer-{version}".format(version = version),
        srcs = [
            "ArtTracer.cpp",
        ],
        headers = native.glob(
            ["*.h"],
            exclude = exported_headers,
        ),
        header_namespace = "profiler",
        exported_headers = {
            header.replace(".h", "_" + version_num + ".h"): header
            for header in exported_headers
        },
        allow_jni_merging = False,
        compiler_flags = [
            "-fvisibility=hidden",
            "-fexceptions",
            "-std=gnu++14",
            "-DLOG_TAG=\"Profilo/ArtCompat\"",
            "-UMUSEUM_VERSION",
            "-DMUSEUM_VERSION=v{}_readonly".format(version_),
            #'-DFBLOG_NDEBUG=0', # extra logging
        ],
        exported_preprocessor_flags = [
            "-DMUSEUM_VERSION_{}".format(version_),
        ],
        force_static = True,
        reexport_all_header_dependencies = False,
        soname = "libprofiloprofiler{version_num}.$(ext)".format(version_num = version_num),
        visibility = [
            "PUBLIC",
        ],
        deps = [
            profilo_path("deps/fb:fb"),
            profilo_path("deps/fbjni:fbjni"),
            profilo_path("deps/forkjail:forkjail"),
            profilo_path("cpp/museum-readonly/{version}/art/runtime:runtime".format(version = version)),
            profilo_path("cpp/logger:logger"),
        ],
    )

def unwindc_tracer_library(version):
    version_num = version.replace(".", "")
    android_version = "android_{}".format(version_num)

    fb_xplat_cxx_library(
        name = "unwindc-tracer-{}".format(version),
        srcs = [
            "ArtUnwindcTracer.cpp",
        ],
        headers = [
            "ArtUnwindcTracer.h",
            "unwindc/runtime.h",
        ],
        header_namespace = "profiler",
        exported_headers = {
            "ArtUnwindcTracer_{}.h".format(version_num): "ArtUnwindcTracer.h",
        },
        compiler_flags = [
            "-fvisibility=hidden",
            "-fexceptions",
            "-std=gnu++14",
            '-DLOG_TAG="Profilo/Unwindc"',
            "-O3",
            "-Wno-self-assign",
            "-Wno-parentheses-equality",
            "-Wno-unused-variable",
        ],
        exported_preprocessor_flags = [
            "-DANDROID_VERSION_{}".format(version_num),
        ],
        force_static = True,
        platform_headers = [
            (".*x86", {
                "unwindc/unwinder.h": "unwindc/{}/x86/unwinder.h".format(android_version),
            }),
            (".*armv7", {
                "unwindc/unwinder.h": "unwindc/{}/arm/unwinder.h".format(android_version),
            }),
        ],
        preprocessor_flags = [
            "-DANDROID_NAMESPACE=android_{}".format(version_num),
            "-DANDROID_VERSION_NUM={}".format(version_num),
        ],
        soname = "libprofiloprofilerunwindc{version_num}.$(ext)".format(version_num = version_num),
        visibility = [
            profilo_path("..."),
        ],
        deps = [
            profilo_path("deps/fb:fb"),
            profilo_path("cpp/logger:logger"),
            profilo_path("cpp/profiler:base_tracer"),
        ],
    )