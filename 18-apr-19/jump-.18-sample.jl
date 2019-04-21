using JuMP
using ProgressMeter
using LinearAlgebra
using SparseArrays
import Gurobi

# Formulates ‖x‖² ≤ y as an SOC
function quad_cons(m, x, y)
    @constraint(m, sum(x.^2) ≤ y )
end

t_min = 1
t_max = 2 - t_min

N = 26  # number of points in domain
freqs = [1, 2, 3]
n_freq = length(freqs) # number of frequencies for the given problem

L_all = []

⊗ = kron

@info "Generating Matrices"

for i=1:n_freq
    global L_all
    w = freqs[i]

    weights = 5*ones(N*N)
    g = zeros(N*N)
    b = zeros(N*N)
    L_1d = (N*N)/(w*w) * Diagonal(ones(N))
    L = L_1d ⊗ sparse(I, N, N)

    push!(L_all, L)
end

z_init = zeros(n_freq, N*N)
t_init = t_min*ones(N*N)

@info "Generating model"

m = Model(solver=Gurobi.GurobiSolver())

@variable(m, nu[1:N*N, 1:n_freq])
@variable(m, t[1:N*N])

@time L_all[1][:,1]' * nu[:,1]

@info "Generating constraints"

@showprogress 1 for j=1:N*N
    quad_cons(m, [ (L_all[i][:,j]' * nu[:,i]) for i=1:n_freq ], t[j])
end