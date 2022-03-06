using Distributions
using HDF5

include("utils.jl")

clients = load_clients("clients.hdf5", "clients/test/22"; scale = 15)
stations = load_map("example-network.json", (-2500, 2500), (0, 250))

client_count = size(clients, 1)
station_count = size(stations, 1)


d = Poisson(0.01)
Γ = 2500rand(d, station_count) .+ 100


d = Normal(1000, 200)
ϕ = rand(d, station_count)


Σ, Π = while true
    d = Poisson(3)
    Σ = rand(d, station_count)

    d = Poisson(0.1)
    Π = rand(d, station_count)
    if all(Π .< Σ)
        return (Σ, Π)
    end
end

k = 20
c = 15000
T = 15 * c

h5open("max_apl_instance.hdf5", "w") do file
    instance = create_group(file, "test3")
    instance["clients"] = clients
    instance["stations"] = stations
    instance["gamma"] = Γ
    instance["phi"] = ϕ
    instance["sigma"] = Σ
    instance["pi"] = Π
    instance["k"] = k
    instance["c"] = c
    instance["T"] = T
end
