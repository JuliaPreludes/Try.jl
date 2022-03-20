using Try: Try, Ok, Err, ConcreteResult

Maybe.ok(result::Ok) = Some{Try.oktype(result)}(result.value)
Maybe.ok(::Err) = nothing
function Maybe.ok(result::ConcreteResult)
    value = result.value
    if value isa Ok
        return Maybe.ok(value)
    else
        return nothing
    end
end

Maybe.err(::Ok) = nothing
Maybe.err(result::Err) = Some{Try.errtype(result)}(result.value)
function Maybe.err(result::ConcreteResult)
    value = result.value
    if value isa Err
        return Maybe.err(value)
    else
        return nothing
    end
end
