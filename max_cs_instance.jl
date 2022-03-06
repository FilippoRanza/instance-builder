using Distributions
using Interpolations
using LinearAlgebra

using YAML
using Configurations

@option struct Config
    output_file::String
    network_file::String
    population_file::String
    population_entry::String
    network_orig_scale::Vector{Float64}
    network_new_scale::Vector{Float64}
end

function load_config(config_file)::Config
    conf = YAML.load_file(config_file; dicttype = Dict{String,Any})
    from_dict(Config, conf)
end



include("utils.jl")
include("time_delay_matrix.jl")
include("save_results.jl")


function build_parcels(count, Λ, initial)
    d = Categorical(Λ)
    out = zeros(Int64, count, 2)
    curr = 1
    while curr <= count
        tmp = rand(d)
        if tmp ≠ initial
            out[curr, :] = [initial tmp]
            curr += 1
        end
    end
    out
end

function csr_paths(count, Λ)
    out = zeros(Int64, count, 3)
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

function try_build_csr(cn, Λ, T, s₀, pn)
    for _ ∈ 1:10000
        csrs = build_csr(cn, Λ₂, T)
        if count(==(s₀), csrs[:, 2]) >= pn
            return csrs
        end
    end
end

function build_instance(Λ₁, Λ₂, T, pn, cn, s₀)
    parcels = build_parcels(pn, Λ₁, s₀)
    csrs = try_build_csr(cn, Λ₂, T, s₀, pn)
    @assert csrs !== nothing
    (parcels, csrs)
end

traffic_anchors = [
    7 0 5
    7 15 5
    7 45 10
    8 15 10
    8 45 6
    9 30 1
    10 0 1
]


config = load_config("config.yml")

apl_stations = [4, 12, 20, 28, 29, 40, 42, 43, 44]

clients = load_clients(config.population_file, config.population_entry; scale = 15)
stations =
    load_map(config.network_file, config.network_orig_scale, config.network_new_scale)[
        apl_stations,
        :,
    ]
time_delay = build_time_delay_matrix(
    config.network_file,
    config.network_orig_scale,
    config.network_new_scale,
    apl_stations,
)

D = make_distance_matrix(clients, stations)

Λ₁ = compute_lambda(D, clients; col = 5)
normalize!(Λ₁, 1)

Λ₂ = compute_lambda(D, clients; col = 4)
normalize!(Λ₂, 1)

T = traffic_prob(traffic_anchors)

csr_count = 500
parcel_count = 50
start_station = 5

parcels, csrs = build_instance(Λ₁, Λ₂, T, parcel_count, csr_count, start_station)
save_results(config.output_file, parcels, csrs, time_delay, length(apl_stations))
