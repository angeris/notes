using JuMP
using LinearAlgebra
using BenchmarkTools
using ProgressMeter
import Random
import SCS

Random.seed!(1234)

function randn_symm(n)
    A = randn(n, n)
    return (A + A')/2
end

function randn_psd(n)
    A = randn(n,n)
    return A * A'
end

function test_diffcp_sdp_example()
    n = 300
    p = 100
    C = randn_psd(n)
    As = [randn_symm(n) for _ ∈ 1:p]
    Bs = randn(p)

    m = Model(with_optimizer(MOIU.MockOptimizer, JuMP._MOIModel{Float64}()))
    @variable(m, X[1:n,1:n])
    @constraint(m, X ∈ PSDCone())
    @showprogress for i ∈ 1:p
        @constraint(m, tr(As[i]*X) == Bs[i])
    end
    @objective(m, Min, tr(C*X))
    optimize!(m)
end

@benchmark test_diffcp_sdp_example()
