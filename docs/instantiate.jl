#!/bin/bash
# -*- mode: julia -*-
#=
JULIA="${JULIA:-julia}"
HERE="$(dirname "${BASH_SOURCE[0]}")"
JULIA_CMD="${JULIA_CMD:-$JULIA --color=yes --startup-file=no --project="$HERE"}"
export JULIA_LOAD_PATH=@:@stdlib  # exclude default environment
exec $JULIA_CMD "${BASH_SOURCE[0]}" "$@"
=#

using Pkg

Pkg.develop([
    PackageSpec(
        name = "Try",
        path = dirname(@__DIR__),
        # url = "https://github.com/tkf/Try.jl.git",
    ),
    PackageSpec(
        name = "TryExperimental",
        path = dirname(@__DIR__),
        # url = "https://github.com/tkf/Try.jl.git",
        subdir = "lib/TryExperimental",
    ),
])

Pkg.instantiate()
