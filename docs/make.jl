using Documenter
using Try

makedocs(
    sitename = "Try",
    format = Documenter.HTML(),
    modules = [Try],
    strict = [
        :autodocs_block,
        :cross_references,
        :docs_block,
        :doctest,
        :eval_block,
        :example_block,
        :footnote,
        :linkcheck,
        :meta_block,
        # :missing_docs,
        :parse_error,
        :setup_block,
    ],
    # Ref:
    # https://juliadocs.github.io/Documenter.jl/stable/lib/public/#Documenter.makedocs
)

# Documenter can also automatically deploy documentation to gh-pages.
# See "Hosting Documentation" and deploydocs() in the Documenter manual
# for more information.
#=deploydocs(
    repo = "<repository url>"
)=#
