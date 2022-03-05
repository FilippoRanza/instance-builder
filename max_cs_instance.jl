using Distributions
using Interpolations
using LinearAlgebra

include("utils.jl")



function build_parcels(count, Λ)
    d = Categorical(Λ)
    out = ones(count, 2)
    out[:, 2] = rand(d, count)
    out
end

function csr_paths(count, Λ)
    out = zeros(count, 3)
    distr = Categorical(Λ)
    curr = 1
    while curr <= count
        s, d = rand(distr, 2)
        if s ≠ d 
            out[curr, 2:3] = [s, d]
            curr += 1
        end
    end 

    out
end

function csr_time(csr, T)
    distr = Categorical(T)
    count = size(csr, 1)
    csr[:, 1] = rand(distr, count)
    csr
end

function build_csr(count, Λ, T)
    csr_paths(count, Λ) |> c -> csr_time(c, T)
end

function hm_to_m(traffic)
    r = size(traffic, 1)
    out = zeros(r, 2)
    for (i, (h, m, t)) in enumerate(eachrow(traffic))
        time = h * 60 + m
        out[i, :] = [time, t] 
    end
    start = out[1, 1]
    out[:, 1] .-= start
    out
end

function traffic_prob(traffic)
    traffic = hm_to_m(traffic)
    x = traffic[:, 1]
    y = traffic[:, 2]
    f = LinearInterpolation(x, y)
    range = x[1]:x[end]
    traffic = f.(range)
    normalize!(traffic, 1)
    traffic
end

traffic_anchors = [
    7 15 5;
    7 45 10;
    8 15 10;
    8 45 4;
    9 30 1;
]



apl_stations = [4, 12, 20, 28, 29, 40, 42, 43, 44]

clients = load_clients("clients.hdf5", "clients/test/22"; scale=15)
stations = load_map("example-network.json", (-2500, 2500), (0, 250))[apl_stations, :]

D = make_distance_matrix(clients, stations)
Λ = compute_lambda(D, clients; col=5)
normalize!(Λ, 1)
parcels = build_parcels(10, Λ)

Λ = compute_lambda(D, clients; col=4)
normalize!(Λ, 1)
T = traffic_prob(traffic_anchors)

csrs = build_csr(200, Λ, T)

@assert count(==(1), csrs[:, 2]) >= 10


h5open("cs-instances.hdf5", "cw") do file

    count = if haskey(file, "count")
        tmp = read(file["count"])
        count = tmp + 1
        write(file["count"], count)
        count
    else
        file["count"] = 1
    end

    instance = create_group(file, "instance-$count")
    instance["parcels"] = parcels
    instance["csrs"] = csrs
end