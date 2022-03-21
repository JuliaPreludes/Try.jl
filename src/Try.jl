baremodule Try

export @?, Ok, Err, Result

using Base: Base, Exception

module InternalPrelude
function _ConcreteResult end
function _IsOkError end
end  # module InternalPrelude

abstract type AbstractResult{T,E} end

struct Ok{T} <: AbstractResult{T,Union{}}
    value::T
end

struct Err{E} <: AbstractResult{Union{},E}
    value::E
    backtrace::Union{Nothing,typeof(Base.backtrace())}
end

const DynamicResult{T,E} = Union{Ok{T},Err{E}}

struct ConcreteResult{T,E} <: AbstractResult{T,E}
    value::DynamicResult{T,E}

    InternalPrelude._ConcreteResult(::Type{T}, ::Type{E}, value) where {T,E} =
        new{T,E}(value)
end

const ConcreteOk{T} = ConcreteResult{T,Union{}}
const ConcreteErr{E} = ConcreteResult{Union{},E}

const Result{T,E} = Union{ConcreteResult{<:T,<:E},DynamicResult{<:T,<:E}}

function unwrap end
function unwrap_err end

function oktype end
function errtype end
function isok end
function iserr end

function enable_errortrace end
function disable_errortrace end

function istryable end
function var"@function" end

# Core exceptions
struct IsOkError <: Exception
    ok::AbstractResult

    InternalPrelude._IsOkError(ok) = new(ok)
end

abstract type NotImplementedError <: Exception end

macro and_then end
macro or_else end

macro and_return end
function var"@?" end

function and_then end
function or_else end

module Internal

import ..Try: @and_return, @?, @and_then, @or_else, @function
using ..Try:
    AbstractResult,
    ConcreteErr,
    ConcreteOk,
    ConcreteResult,
    DynamicResult,
    Err,
    Ok,
    Result,
    Try
using ..Try.InternalPrelude: _ConcreteResult, _IsOkError

using Base.Meta: isexpr

include("ExternalDocstrings.jl")
using .ExternalDocstrings: @define_docstrings

include("core.jl")
include("show.jl")
include("errortrace.jl")
include("function.jl")

include("branch.jl")

include("sugar.jl")

end  # module Internal

Internal.@define_docstrings

end  # baremodule Try
