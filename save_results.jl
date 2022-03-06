function save_results(file_name, parcels, csrs, time_delay, stats_count)
    h5open(file_name, "cw") do file

        count = if haskey(file, "count")
            tmp = read(file["count"])
            count = tmp + 1
            write(file["count"], count)
            count
        else
            file["count"] = 1
        end
        println(count)

        instance = create_group(file, "instance-$count")
        instance["parcels"] = parcels
        instance["csrs"] = csrs
        instance["delay"] = time_delay
        instance["wait"] = 2ones(stats_count)
    end
end
