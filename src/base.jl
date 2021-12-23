Try.convert(::Type{T}, x::T) where {T} = Ok(x)  # TODO: should it be `Ok{T}(x)`?

const MightHaveSize = Union{AbstractArray,AbstractDict,AbstractSet,AbstractString,Number}

Try.length(xs::MightHaveSize)::Result =
    if IteratorSize(xs) isa Union{HasLength,HasShape}
        return Ok(length(xs))
    else
        return Causes.notimplemented(Try.length, (xs,))
    end

Try.eltype(xs) = Try.eltype(typeof(xs))
Try.eltype(T::Type) = Causes.notimplemented(Try.eltype, (T,))
Try.eltype(::Type{Union{}}) = Causes.notimplemented(Try.eltype, (Union{},))
Try.eltype(::Type{<:AbstractArray{T}}) where {T} = Ok(T)
Try.eltype(::Type{AbstractSet{T}}) where {T} = Ok(T)

Try.eltype(::Type{Dict}) where {K,V,Dict<:AbstractDict{K,V}} = eltype_impl(Dict)
Try.eltype(::Type{Num}) where {Num<:Number} = eltype_impl(Num)
Try.eltype(::Type{Str}) where {Str<:AbstractString} = eltype_impl(Str)

eltype_impl(::Type{T}) where {T} =
    if IteratorEltype(T) isa HasEltype
        return Ok(eltype(T))
    else
        return Causes.notimplemented(Try.eltype, (T,))
    end

@inline function Try.getindex(a::AbstractArray, i...)::Result
    (@boundscheck checkbounds(Bool, a, i...)) || return Err(BoundsError(a, i))
    return Ok(@inbounds a[i...])
end

@inline function Try.setindex!(a::AbstractArray, v, i...)::Result
    (@boundscheck checkbounds(Bool, a, i...)) || return Err(BoundsError(a, i))
    @inbounds a[i...] = v
    return Ok(v)
end

struct NotFound end

function Try.getindex(dict::AbstractDict, key)::Result
    value = get(dict, key, NotFound())
    value isa NotFound && return Err(KeyError(key))
    return Ok(value)
end

function Try.setindex!(dict::AbstractDict, value, key)::Result
    dict[key] = value
    return Ok(value)
end

Try.getindex(dict::AbstractDict, k1, k2, ks...) = Try.getindex(dict, (k1, k2, ks...))
Try.setindex!(dict::AbstractDict, v, k1, k2, ks...) =
    Try.setindex!(dict, v, (k1, k2, ks...))

Try.pop!(a::Vector)::Result = isempty(a) ? Causes.empty(a) : Ok(pop!(a))
Try.popfirst!(a::Vector)::Result = isempty(a) ? Causes.empty(a) : Ok(popfirst!(a))

function Try.push!(a::Vector, x)::Result
    y = Try.@return_err Try.convert(eltype(a), x)
    push!(a, y)
    return Ok(a)
end

function Try.pushfirst!(a::Vector, x)::Result
    y = Try.@return_err Try.convert(eltype(a), x)
    pushfirst!(a, y)
    return Ok(a)
end

function Try.take!(ch::Channel)::Result
    y = iterate(ch)
    y === nothing && return Causes.empty(ch)
    return Ok(first(y))
end

function Try.put!(ch::Channel, x)::Result
    isopen(ch) || return Causes.closed(ch)
    y = Try.@return_err Try.convert(eltype(ch), x)
    try
        put!(ch, x)
    catch err
        err isa InvalidStateException && !isopen(ch) && return Causes.closed(ch)
        rethrow()
    end
    return Ok(y)
end
