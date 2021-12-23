function extract_thunk(f)
    if isexpr(f, :->, 2) && isexpr(f.args[1], :tuple, 1)
        arg, = f.args[1].args
        body = f.args[2]
        return (arg, body)
    else
        error("invalid argument: ", f)
    end
end

macro and_then(f, ex)
    arg, body = extract_thunk(f)
    quote
        result = $(esc(ex))
        if Try.isok(result)
            let $(esc(arg)) = Try.unwrap(result)
                $(esc(body))
            end
        else
            result
        end
    end
end

macro or_else(f, ex)
    arg, body = extract_thunk(f)
    quote
        result = $(esc(ex))
        if Try.iserr(result)
            let $(esc(arg)) = Try.unwrap_err(result)
                $(esc(body))
            end
        else
            result
        end
    end
end

const var"@_return" = var"@return"

macro _return(ex)
    quote
        result = $(esc(ex))
        if Try.isok(result)
            return result
        else
            Try.unwrap_err(result)
        end
    end
end

macro return_err(ex)
    quote
        result = $(esc(ex))
        if Try.iserr(result)
            return result
        else
            Try.unwrap(result)
        end
    end
end
