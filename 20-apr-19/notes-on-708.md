## Some quick notes on why this might be a good idea (and, potentially, a terrible one)

The initial problem came up when attempting to optimize a (relatively small)
problem with a large number of reshapes and concatenations. It seemed that JuMP
would heavily outperform CVXPY in a similar problem of this form, but it was
somewhat unclear why this would be the case.

When profiling this, @akshayka found a few things: (a) `is_constant` and many similar methods were being recomputed, even though most atoms are essentially immutable (fixed by 9b59d045ef8) and (b) that a huge chunk of time was being spent by `cvxcore` in generating the correct affine transformations. This is particularly surprising, since most of the affine expressions present in the program are mostly concerned with stacking and concatenating matrices and vectors (note that the size of the final program was moderate: 4000 variables with ~4000 very sparse SOC constraints, generated essentially by a tridiagonal matrix). For more information, take a peek at [this profile dump](XXX) of the code.

Another somewhat large chunk of time seems to be spent converting and checking the validity of sparse matrices (e.g., calls to `coo.py:_check`, from SciPy) and similar things. This, at least to me, appears to be that there are a large number of unnecessary conversions between formats or that too many operations are being performed on these matrices, even though most of them will have a very small number of nonzero entries.

So, this generates some ideas, which might be interesting to try and implement (not all of them independent of each other):
1. Full elementwise construction of `build_matrix` either during the construction of the parse tree or after.
2. Elementwise construction of all (and only) the sub-indexing or stacking expressions, etc. More specifically, the types of operations that generate submatrices of the identity or kronecker products thereof, and leaving the rest for cvxcanon.
3. Working on a DP-type approach as @rileyjmurray suggested in the second post. This part is fairly unclear to me, as (unlike in the sense case) it seems that different sparsity patterns will yield very different matrix-build times. I'm also not sure if this is being done in the dense case? @SteveDiamond ?

Number 1 is essentially JuMP's approach. This yields somewhat similar times in the current CVXPY implementation, for example, when naïvely translating `test_benchmarks.py:TestBenchmarks.test_diffcp_sdp_example` to Julia, as in [this gist](https://gist.github.com/angeris/e2d766e44ba8081b200dea4cf085fbcf). Of course, the CVXPY `tr` function could be a bit smarter about computing the correct result, but that's another point. There are a few questions, though: (a) Python isn't Julia in terms of element-wise speed, of course, so we may not be able to get away with this, unlike JuMP. But the question remains: what is the performance impact for most problems? This is sort-of addressed by suggestion 2, which attempts a "best-of-both-worlds" approach, but then (b) what should the interface look like between cvxcore and cvxpy? Almost all of these matrix-building operations are currently being sent off to cvxcore, but now we have some transformations done within cvxpy and others within cvxcore. Unsure of what the implications in terms of structure are, but with the decreased communication cost and likely reduced number of operations, it's worth thinking about.

Suggestion 3 strikes me as somewhat sensible, since it's quite possible that a simple heuristic will do quite well in the sparse case, but it's not clear to me what such a heuristic would look like (the suggestion above may be good, but I really don't have much intuition about what the results might be).

Anyways, I likely forgot a few things on this topic, so I may come back and edit this later comment, but this is, at the moment, where we are at.

Additionally, apologies for the partial response, @rileyjmurray : I haven't thought enough about your first suggestion to fully appreciate it, though it's likely that @akshayka and @SteveDiamond have some thoughts?