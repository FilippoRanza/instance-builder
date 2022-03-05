
using JSON

include("utils.jl")

clients = load_clients("clients.hdf5", "clients/test/22"; scale=10)

stations = load_map("example-network.json", (-2500, 2500), (0, 250))

dist = make_distance_matrix(clients, stations)

Λ = compute_lambda(dist, clients)

output = Dict(
    "lambda_coeff" => Λ,
    "distances" => dist
)

open("instance.json", "w") do file
    JSON.print(file, output)
end