using JuMP
using LinearAlgebra
using SparseArrays

# Formulates ‖x‖² ≤ y as an SOC
function quad_cons(m, x, y)
    @constraint(m, sum(x.^2) ≤ y )
end

const t_min = 1
const t_max = 2 - t_min

const N = 26  # number of points in domain
const freqs = [1, 2, 3]
const n_freq = length(freqs) # number of frequencies for the given problem

function test_all()
    ⊗ = kron

    @info "Generating Matrices"

    L_1d = sparse(I, N, N)
    L = L_1d ⊗ L_1d

    z_init = zeros(n_freq, N*N)
    t_init = t_min*ones(N*N)

    @info "Generating model"

    m = Model()

    @variable(m, nu[1:N*N, 1:n_freq])
    @variable(m, t[1:N*N])

    @info "Timing multiply"
    @time L[:,1]' * nu[:,1]
    @time L[:,1]' * nu[:,1]

    @info "Normal expression"
    @time quad_cons(m, [ (L[:,1]' * nu[:,1]) for i=1:n_freq ], t[1])
    @time quad_cons(m, [ (L[:,1]' * nu[:,1]) for i=1:n_freq ], t[1])

    @info "Scalarized expression"
    @time quad_cons(m, [ sum(L[k,1] * nu[k,1] for k=1:N*N) for i=1:n_freq ], t[1])
    @time quad_cons(m, [ sum(L[k,1] * nu[k,1] for k=1:N*N) for i=1:n_freq ], t[1])

    @info "Fully expanded expression"
    @time @constraint(m, sum(sum(L[k,1] * nu[k,1] for k=1:N*N)^2 for i=1:n_freq) ≤ t[1])
    @time @constraint(m, sum(sum(L[k,1] * nu[k,1] for k=1:N*N)^2 for i=1:n_freq) ≤ t[1])
end

test_all()