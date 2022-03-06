import Graphs
import SimpleWeightedGraphs

include("utils.jl")

struct Network
    lines::Vector{Vector{Int64}}
    points::Matrix{Float32}
end

function build_time_delay_matrix(file_name, I₁, I₂, apl_stats)
    net = load_network(file_name, I₁, I₂)
    graph = build_graph(net)
    fws = Graphs.floyd_warshall_shortest_paths(graph)
    dists = fws.dists
    extract_matrix(dists, apl_stats) |> remove_self_arc |> min_normalize
end

function min_normalize(M)
    M ./= minimum(M)
    M
end

function remove_self_arc(M)
    for i = 1:size(M, 1)
        M[i, i] = Inf
    end
    M
end

function extract_matrix(full_mat, indexes)
    out = zeros(length(indexes), length(indexes))
    for (i, x) in enumerate(indexes)
        for (j, y) in enumerate(indexes)
            out[i, j] = full_mat[x, y]
        end
    end
    out
end

function build_graph(net::Network)
    nodes = size(net.points, 1)
    graph = SimpleWeightedGraphs.SimpleWeightedGraph(nodes)
    for line in net.lines
        prev = nothing
        for s in line
            if prev !== nothing
                push_nodes!(graph, prev, s, net)
            end
            prev = s
        end
    end
    graph
end

function push_nodes!(g, s₁, s₂, net::Network)
    d = get_distance(s₁, s₂, net)
    @assert d > 0
    if !(Graphs.add_edge!(g, s₁ + 1, s₂ + 1, d))
        println("ERROR: $s₁, $s₂, $d")
    end
end

function get_distance(s₁, s₂, net::Network)
    p₁ = get_point(s₁, net)
    p₂ = get_point(s₂, net)
    euclid_distance(p₁, p₂)
end

function get_point(s_id, net::Network)
    net.points[s_id+1, :]
end

function load_network(file_name, I₁, I₂)
    open(file_name) do file
        raw_net = JSON.parse(file)
        lines = get_lines(raw_net["lines"])
        points = get_points(raw_net["points"], I₁, I₂)
        Network(lines, points)
    end
end

function get_lines(raw_lines)
    [convert(Vector{Int64}, l) for l in raw_lines]
end

function get_points(raw_points, I₁, I₂)
    output = zeros(length(raw_points), 2)
    for (i, (x, y)) in enumerate(raw_points)
        output[i, :] = [x y]
    end
    f = convert_inteval(I₁, I₂)
    f.(output)
end
