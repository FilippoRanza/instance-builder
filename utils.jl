using HDF5
using JSON

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
