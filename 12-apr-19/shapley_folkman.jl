using PyPlot

N = 1000

function quasi_convex(x)
    return min.(2*x.^2, 5)
end

x = Array(range(-10, 10, length=N))

plot(x, quasi_convex(x))
savefig("quasi_convex.png")
close()

total = zeros(N)

trials = 1000000

for i = 1:trials
    offset = 10*rand()-5
    total .+= quasi_convex(x .+ offset)

    if i ∈ [1, 10, 100, 1000, 10000, 100000, 1000000]
        plot(x, total/i)
        title("Sum of $(i) functions")
        savefig("aggregate_$(i).png")
        close()
    end
end
