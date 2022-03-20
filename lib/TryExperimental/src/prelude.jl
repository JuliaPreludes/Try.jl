using Try

macro reexport_try()
    exprs = []

    mapfoldl(append!, names(Try; all = true); init = exprs) do name
        value = try
            getproperty(Try, name)
        catch err
            @error "Cannot access `Try.$name`" exception = (err, catch_backtrace())
            return []
        end
        (value isa Module && value !== Try.Causes) && return []
        return [:(const $name = $Try.$name)]
    end

    public_names = filter(!=(:Try), names(Try))
    export_expr = :(export $(public_names...))

    return esc(Expr(:block, __source__, exprs..., export_expr))
end
