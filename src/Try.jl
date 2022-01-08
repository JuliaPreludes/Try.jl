baremodule Try

export Ok, Err, Result

using Base: Base, Exception

abstract type AbstractResult{T,E<:Exception} end

struct Ok{T} <: AbstractResult{T,Union{}}
    value::T
end

struct Err{E<:Exception} <: AbstractResult{Union{},E}
    value::E
    backtrace::Union{Nothing,typeof(Base.backtrace())}
end

const DynamicResult{T,E} = Union{Ok{T},Err{E}}

function _ConcreteResult end

struct ConcreteResult{T,E<:Exception} <: AbstractResult{T,E}
    value::DynamicResult{T,E}
    global _ConcreteResult(::Type{T}, ::Type{E}, value) where {T,E} = new{T,E}(value)
end

const ConcreteOk{T} = ConcreteResult{T,Union{}}
const ConcreteErr{E<:Exception} = ConcreteResult{Union{},E}

const Result{T,E} = Union{ConcreteResult{T,E},DynamicResult{T,E}}

function throw end

function unwrap end
function unwrap_err end

function ok end
function err end
function oktype end
function errtype end
function isok end
function iserr end

function enable_errortrace end
function disable_errortrace end

abstract type Tryable <: Function end

# Core exceptions
struct IsOkError <: Exception
    ok::AbstractResult{<:Any,Union{}}
end

# Basic exceptions
abstract type NotImplementedError <: Exception end
abstract type ClosedError <: Exception end
abstract type EmptyError <: Exception end
abstract type FullError <: Exception end

baremodule Causes
function notimplemented end
function empty end
function closed end
end  # baremodule Cause

macro and_then end
macro or_else end
macro return_err end
function var"@return" end
function var"@function" end

function and_then end
function or_else end

module Internal

import ..Try: @return, @return_err, @and_then, @or_else, @function
using ..Try:
    AbstractResult,
    Causes,
    ConcreteErr,
    ConcreteOk,
    ConcreteResult,
    DynamicResult,
    Err,
    Ok,
    Result,
    Try,
    _ConcreteResult

using Base.Meta: isexpr

include("utils.jl")
include("core.jl")
include("show.jl")
include("errortrace.jl")
include("function.jl")
include("causes.jl")

include("tools.jl")
include("sugar.jl")

end  # module Internal

@function convert
# @function promote

# Collection interface
@function length
@function eltype

@function getindex
@function setindex!

@function first
@function last

@function push!
@function pushfirst!
@function pop!
@function popfirst!

@function put!
@function take!

@function push_nowait!
@function pushfirst_nowait!
@function pop_nowait!
@function popfirst_nowait!

@function put_nowait!
@function take_nowait!

module Implementations
using ..Try
using ..Try: Causes
using Base: IteratorEltype, HasEltype, IteratorSize, HasLength, HasShape
include("base.jl")
end  # module Implementations

Internal.define_docstrings()

end  # baremodule Try
