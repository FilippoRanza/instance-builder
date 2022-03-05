using HDF5
using JSON

function make_distance_matrix(clients, stations)
    c = size(clients, 1)
    s = size(stations, 1)
    
    dist = zeros(s, c)
    for i in 1:c
        for j in 1:s
            dist[j, i] = euclid_distance(clients[i, 1:2], stations[j, :])
        end
    end
    dist
end


function compute_lambda(distance, clients; col=4)
    s = size(distance, 1)
    Λ = zeros(s)
    for i = 1:s
        Λ[i] = mapreduce((d, p) -> exp(-d/p), +, distance[:, i], clients[:, col])
    end
    Λ
end



function convert_inteval(i₁, i₂)
    x₁, x₂ = i₁
    y₁, y₂ = i₂

    A = [x₁ 1; x₂ 1]
    b = [y₁; y₂]
    a, b = A \ b
    (x) -> a*x + b
end

function euclid_distance(p₁, p₂)
    x₁, y₁ = p₁
    x₂, y₂ = p₂
    dx = (x₁ - x₂)^2
    dy = (y₁ - y₂)^2
    √(dx + dy)
end

function scale_distances!(clients, scale)
    clients[:, 4:5] ./= scale
    clients
end

function load_clients(file_name, data_entry; scale=1)
    h5open(file_name) do data
        read(data[data_entry]) |> M -> scale_distances!(M, scale) 
    end
end


function load_map(file_name, orig_int, new_int)
    f = convert_inteval(orig_int, new_int)
    open(file_name) do file
        net = JSON.parse(file)
        data = net["points"]
        output = zeros(length(data), 2)
        for i ∈ 1:length(data)
            output[i, 1] = data[i][1]
            output[i, 2] = data[i][2]
        end
        f.(output)
    end
end
