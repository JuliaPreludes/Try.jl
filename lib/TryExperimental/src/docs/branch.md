    TryExperiment.branch(result) -> Continue(result)
    TryExperiment.branch(result) -> Break(result)

`branch` implements a short-circuiting evaluation API.  It must return a `Continue` or a
`Break`.
