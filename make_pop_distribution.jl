
include("utils.jl")


clients = load_clients("clients.hdf5", "clients/test/22"; scale = 15)

clients = clients[:, 1:3]

open("pop-distribution.json", "w") do file
    JSON.print(file, clients')
end
