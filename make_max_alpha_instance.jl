
using JSON

include("utils.jl")



function compute_lambda(distance, clients)
    s = size(distance, 1)
    Λ = zeros(s)
    for i = 1:s
        Λ[i] = mapreduce((d, p) -> exp(-d/p), +, distance[:, i], clients[:, 4])
    end
    Λ
end

clients = load_clients("clients.hdf5", "clients/test/22"; scale=10)

f = convert_inteval((-2500, 2500), (0, 250))
stations = load_map("example-network.json", (-2500, 2500), (0, 250))

c = size(clients, 1)
s = size(stations, 1)

dist = zeros(s, c)
for i in 1:c
    for j in 1:s
        dist[j, i] = euclid_distance(clients[i, 1:2], stations[j, :])
    end
end

Λ = compute_lambda(dist, clients)

output = Dict(
    "lambda_coeff" => Λ,
    "distances" => dist
)

open("instance.json", "w") do file
    JSON.print(file, output)
end