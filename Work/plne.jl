using JuMP, Gurobi

#INCLUDES
include("dimensions.jl")
include("emballage.jl")
include("usine.jl")
include("fournisseur.jl")
include("graphe.jl")
include("instance.jl")
include("route.jl")
include("solution.jl")
include("write.jl")

function formatClusters(clusters::Array{Array{Int64,2},1})
    newClusters = Array{Array{Int64,1},1}(undef, 0)
    for cluster in clusters
        for f in 1:size(cluster, 1)
            newCluster = Array{Int64,1}(undef, 0)
            if cluster[f] == 1
                push!(newCluster, f)
            end
        end
        push!(newClusters, newCluster)
    end
    return newClusters
end


function solve_plne(instance::Instance, clusters::Array{Array{Int64,2},1})
    sol_clusters = Array{Array{Int64,4}, 1}
    for e = 1:instance.E
        model = Model(Gurobi.Optimizer)

        #= On sépare par clusters i, ensuite la 1ère coord correspond au jour, la 2e au départ et la 3e à la destination
        Dans le départ et la destination on met les 4 fournisseurs en premiers, suivi des instance.U usines
        (d[i, j, 1, 2]) == 1 si dans le cluster i un camion va du 1er fournisseur au 2e =#

        @variable(model, d[1:size(clusters, 1), 1:instance.J, 1:(4 + instance.U), 1:(4 + instance.U)], Bin)
        @variable(model, x[1:size(clusters, 1), 1:instance.J, 1:(4 + instance.U), 1:(4 + instance.U)], Int)
        @variable(model, s[1:size(clusters, 1), 1:instance.J, 1:(4 + instance.U)], Int)
        @variable(model, s1[1:size(clusters, 1), 1:instance.J, 1:(4 + instance.U)], Int)
        @variable(model, s2[1:size(clusters, 1), 1:instance.J, 1:(4 + instance.U)], Int)

        for i = 1:size(clusters, 1)
            for j = 1:instance.J
                for a = 1:(instance.J + 4)
                    for b = 1:(instance.J + 4)
                        @constraint(model, x[i, j, a, b] <= instance.L * d[i, j, a, b])
                        @constraint(model, x[i, j, a, b] >= d[i, j, a, b])
                        @constraint(model, x[i, j, a, b] >= 0)
                    end
                end
            end
        end

        @objective(
            model,
            Min,
            sum(
                sum(
                    sum(sum(d[i, j, a, b] * (instance.γ * 1 + instance.cstop)) for a = 1:(4 + instance.U)) for b = 1:(4 + instance.U)
                    +
                    sum(instance.usines[u - 4].cs[e] * (s1[i, j, u] - instance.usines[u - 4].r[e, j])) for u = 5:(4 + instance.U)
                    +
                    sum(instance.fournisseurs[clusters[i][f]].cs[e] * (s1[i, j, f] - instance.fournisseurs[clusters[i][f]].r[e, j])
                    + instance.fournisseurs[clusters[i][f]].cexc[e] * (s2[i, j, f] - s[i, j, f])) for f = 1:4
                ) for j = 1:instance.J
            ) for i = 1:size(clusters, 1)
        )

        JuMP.optimize!(model)

        for j = 1:instance.J
            for i = 1:size(clusters, 1)
                for a = 1:(4 + instance.U)
                    for b = 1:(4 + instance.U)
                        sol_clusters[i][e, j, a, b] = JuMP.value(x[i, j, a, b])
                    end
                end
            end
        end
    end
    println("Objectif : ")
    println(JuMP.objective_value(model))
    return sol_clusters
end

