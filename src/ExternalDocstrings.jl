"""
    ExternalDocstrings

ExternalDocstrings.jl is a helper for writing docstrings in markdown files.

# Usage

Create markdown files in `src/docs/` (where `src/MyPackage.jl` is the main package source
file).  Put the following line inside of `MyPackage` namespace:

```julia
ExternalDocstrings.@define_docstrings
```

It defines a docstring for name `MyPackage.\$name` using the markdown content in
`src/docs/\$name.md`.

# Extended help

## Markdown transformations

To use standard markdown (and CommonMark) while supporting special syntaxes for Julia
docstring, ExternalDocstrings.jl performs a couple of transformations:

(1) Code fence notation

    ```julia
    # ...
    ```

is transformed into

    ```jldoctest LABEL
    # ...
    ```

where `LABEL` is a label unique to the markdown file (i.e., all code blocks in one markdown
file are executed in the same session).

(2) To help doctests for non-REPL code block,

    nothing  # hide
    # output

is inserted at the end of code block if it does not look like a REPL session and does not
already have `# output`.

(3) `<kbd>KEY</kbd>` is replaced by `_KEY_`.

## Tips

### Disable doctest

To enable syntax highlighting without doctest, use use slightly different code fence
notations such as

    ```JULIA
    this_is_not_doctested() = nothing
    ```

### Vendoring

ExternalDocstrings.jl written as a single-source package to help vendoring.  For example, it
can be installed simply by:

```bash
wget https://raw.githubusercontent.com/tkf/ExternalDocstrings.jl/main/src/ExternalDocstrings.jl -O src/ExternalDocstrings.jl
```
"""
module ExternalDocstrings
#=
MIT License

Copyright (c) 2022 Takafumi Arakaki <aka.tkf@gmail.com> and contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
=#

function transform_docstring(doc::AbstractString, label)
    output = IOBuffer()
    input = IOBuffer(doc)
    while !eof(input)
        ln = readline(input)
        if startswith(ln, "```julia")
            print(output, "```jldoctest ", label, "\n")
            isrepl = false
            hasoutput = false
            while !eof(input)
                ln = readline(input)
                if startswith(ln, "```")
                    if !isrepl && !hasoutput
                        print(
                            output,
                            """
                            nothing  # hide
                            # output
                            """,
                        )
                    end
                    print(output, ln, "\n")
                    break
                end
                print(output, ln, "\n")
                if startswith(ln, "julia> ")
                    isrepl = true
                elseif startswith(ln, "# output")
                    hasoutput = true
                end
            end
        else
            ln = replace(ln, r"<kbd>(.*?)</kbd>" => s"_\1_")
            print(output, ln, "\n")
        end
    end
    return String(take!(output))
end

function define_docstrings(pkg::Module)
    if pathof(pkg) === nothing
        @warn """
        `define_docstrings` called on a non-package module `$pkg`.
        Not defining docstrings.
        """
        return
    end
    srcdir = dirname(pathof(pkg))
    docstrings = [nameof(pkg) => joinpath(dirname(srcdir), "README.md")]
    docsdir = joinpath(srcdir, "docs")
    if isdir(docsdir)
        for filename in readdir(docsdir)
            stem, ext = splitext(filename)
            ext == ".md" || continue
            name = Symbol(stem)
            name in names(pkg, all = true) || continue
            push!(docstrings, name => joinpath(docsdir, filename))
        end
    end
    n_auto_labels = 0
    for (name, path) in docstrings
        label = string(name)
        if match(r"^[a-z0-9_]+$"i, label) === nothing
            label = "$(nameof(pkg))$n_auto_labels"
            n_auto_labels += 1
        end

        include_dependency(path)
        doc = read(path, String)
        doc = transform_docstring(doc, label)

        ex = :($Base.@doc $doc $name)
        ex.args[2]::LineNumberNode
        ex.args[2] = LineNumberNode(1, Symbol(path))

        Base.eval(pkg, ex)
    end
end

macro define_docstrings()
    :(define_docstrings($(QuoteNode(__module__))))
end

end
