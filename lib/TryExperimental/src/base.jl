tryconvert(::Type{T}, x::T) where {T} = Ok(x)  # TODO: should it be `Ok{T}(x)`?

const MightHaveSize = Union{AbstractArray,AbstractDict,AbstractSet,AbstractString,Number}

trygetlength(xs::MightHaveSize)::Result =
    if IteratorSize(xs) isa Union{HasLength,HasShape}
        return Ok(length(xs))
    else
        return Causes.notimplemented(trygetlength, (xs,))
    end

trygeteltype(xs) = trygeteltype(typeof(xs))
trygeteltype(T::Type) = Causes.notimplemented(trygeteltype, (T,))
trygeteltype(::Type{Union{}}) = Causes.notimplemented(trygeteltype, (Union{},))
trygeteltype(::Type{<:AbstractArray{T}}) where {T} = Ok(T)
trygeteltype(::Type{AbstractSet{T}}) where {T} = Ok(T)

trygeteltype(::Type{Dict}) where {K,V,Dict<:AbstractDict{K,V}} = eltype_impl(Dict)
trygeteltype(::Type{Num}) where {Num<:Number} = eltype_impl(Num)
trygeteltype(::Type{Str}) where {Str<:AbstractString} = eltype_impl(Str)

eltype_impl(::Type{T}) where {T} =
    if IteratorEltype(T) isa HasEltype
        return Ok(eltype(T))
    else
        return Causes.notimplemented(trygeteltype, (T,))
    end

@inline function trygetindex(a::AbstractArray, i...)::Result
    checkbounds(Bool, a, i...) || return Err(BoundsError(a, i))
    return Ok(@inbounds a[i...])
end

@inline function trysetindex!(a::AbstractArray, v, i...)::Result
    checkbounds(Bool, a, i...) || return Err(BoundsError(a, i))
    @inbounds a[i...] = v
    return Ok(v)
end

@inline function trygetindex(xs::Tuple, i::Integer)::Result
    i < 1 && return Err(BoundsError(xs, i))
    i > length(xs) && return Err(BoundsError(xs, i))
    return Ok(xs[i])
end

struct NotFound end

function trygetindex(dict::AbstractDict, key)::Result
    value = get(dict, key, NotFound())
    value isa NotFound && return Err(KeyError(key))
    return Ok(value)
end

function trysetindex!(dict::AbstractDict, value, key)::Result
    dict[key] = value
    return Ok(value)
end

trygetindex(dict::AbstractDict, k1, k2, ks...) = trygetindex(dict, (k1, k2, ks...))
trysetindex!(dict::AbstractDict, v, k1, k2, ks...) = trysetindex!(dict, v, (k1, k2, ks...))

trygetfirst(xs) = trygetindex(xs, 1)
trygetlast(xs) = trygetindex(xs, lastindex(xs))

trypop!(a::Vector)::Result = isempty(a) ? Causes.empty(a) : Ok(pop!(a))
trypopfirst!(a::Vector)::Result = isempty(a) ? Causes.empty(a) : Ok(popfirst!(a))

function trypush!(a::Vector, x)::Result
    y = @? tryconvert(eltype(a), x)
    push!(a, y)
    return Ok(a)
end

function trypushfirst!(a::Vector, x)::Result
    y = @? tryconvert(eltype(a), x)
    pushfirst!(a, y)
    return Ok(a)
end

function trytake!(ch::Channel)::Result
    y = iterate(ch)
    y === nothing && return Causes.empty(ch)
    return Ok(first(y))
end

function tryput!(ch::Channel, x)::Result
    isopen(ch) || return Causes.closed(ch)
    y = @? tryconvert(eltype(ch), x)
    try
        put!(ch, x)
    catch err
        err isa InvalidStateException && !isopen(ch) && return Causes.closed(ch)
        rethrow()
    end
    return Ok(y)
end
