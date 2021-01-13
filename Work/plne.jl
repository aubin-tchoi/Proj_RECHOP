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

function formatClusters(instance::Instance, clusters::Array{Array{Int64,2},1})
    newClusters = Array{Array{Int64,1},1}(undef, 0)
    for c = 1:size(clusters, 1)
        newCluster = Array{Int64,1}(undef, 0)
        for f in 1:size(clusters[c], 2)
            if clusters[c][1,f] == 1
                push!(newCluster, f)
            end
        end
        push!(newClusters, newCluster)
    end
    return newClusters
end

function solve_plne(instance::Instance, clusters::Array{Array{Int64,1},1}, K::Int64)
    sol_clusters = Array{Int64, 6}(undef, instance.E, size(clusters, 1), instance.J, K, 4 + instance.U, 4 + instance.U)
    val = 0
    for e = 1:instance.E
        println("DEBUT OK")
        model = Model(with_optimizer(Gurobi.Optimizer,  TimeLimit = 10))
        println("MODEL OK")
        #= On sépare par clusters i, ensuite la 1ère coord correspond au jour, la 2e au départ et la 3e à la destination
        Dans le départ et la destination on met les 4 fournisseurs en premiers, suivi des instance.U usines
        (d[i, j, k, 1, 2]) == 1 si dans le cluster i le camion k va du 1er fournisseur au 2e =#

        @variable(model, d[1:size(clusters, 1), 1:instance.J, 1:K, 1:(4 + instance.U), 1:(4 + instance.U)], Bin)
        @variable(model, x[1:size(clusters, 1), 1:instance.J, 1:K, 1:(4 + instance.U), 1:(4 + instance.U)], Int)
        @variable(model, s[1:size(clusters, 1), 1:instance.J, 1:(4 + instance.U)], Int)
        @variable(model, s1[1:size(clusters, 1), 1:instance.J, 1:(4 + instance.U)], Int)
        @variable(model, s2[1:size(clusters, 1), 1:instance.J, 1:(4 + instance.U)], Int)

        println("VARIABLES OK")

        # delta
        for i = 1:size(clusters, 1)
            for j = 1:instance.J
                for k = 1:K
                    for a = 1:(instance.U + 4)
                        for b = 1:(instance.U + 4)
                            # McCormick
                            @constraint(model, x[i, j, k, a, b] <= instance.L * d[i, j, k, a, b])
                            @constraint(model, x[i, j, k, a, b] >= d[i, j, k, a, b])
                            @constraint(model, x[i, j, k, a, b] >= 0)
                        end
                        # On ne se livre pas à soi-même
                        @constraint(model, d[i, j, k, a, a] == 0)

                        # En partant d'un sommet on peut aller vers 1 seul autre sommet (au plus 1 destination)
                        @constraint(model, sum(d[i, j, k, a, b] for b = 1:(instance.U + 4)) <= 1)

                        # 0 si jamais le cluster contient moins de 4 éléments
                        @constraint(model, sum(d[i, j, k, a, b] for b = (size(clusters[i], 1) + 1):4) == 0)
                        @constraint(model, sum(d[i, j, k, b, a] for b = (size(clusters[i], 1) + 1):4) == 0)

                    end
                end
            end
        end

        # Stocks
        for i = 1:size(clusters, 1)
            for j = 1:instance.J
                for u = 1:instance.U
                    # s' pour linéariser le max(s-r, 0)
                    @constraint(model, s1[i, j, u + 4] >= instance.usines[u].r[e, j])
                end
                for a = 1:(4 + instance.U)
                    # s' et s"
                    @constraint(model, s1[i, j, a] >= s[i, j, a])
                    @constraint(model, s2[i, j, a] >= s[i, j, a])
                end
            end
        end

        # Usines
        for i = 1:size(clusters, 1)
            for j = 1:instance.J
                for u = 1:instance.U
                    # Stock positif pour les usines
                    @constraint(model, s[i, j, u + 4] >= 0)
                    # Évolution du stock
                    if j == 1
                        @constraint(model, s[i, j, u + 4] == instance.usines[u].s0[e])
                    elseif j >= 2
                        @constraint(model, s[i, j, u + 4] - s[i, j - 1, u + 4] + sum(sum(x[i, j, k, u, b] for b = 1:(4 + instance.U)) for k = 1:K) == instance.usines[u].b⁺[e, j])
                    end
                end
            end
        end

        println(size(instance.fournisseurs))
        println(size(clusters))
        println(clusters)

        # Fournisseurs
        for i = 1:size(clusters, 1)
            for j = 1:instance.J
                for f = 1:size(clusters[i], 1)
                    if j >= 2
                        @constraint(model, s[i, j, f] - sum(sum((x[i, j, k, a, f] - x[i, j, k, f, a]) for a = 1:(4 + instance.U)) for k = 1:K) >= s[i, j - 1, f] - instance.fournisseurs[clusters[i][f]].b⁻[e, j])
                        @constraint(model, s2[i, j - 1, f] >= instance.fournisseurs[clusters[i][f]].b⁻[e, j])
                    end
                    @constraint(model, s[i, j, f] - sum(sum((x[i, j, k, a, f] - x[i, j, k, f, a]) for a = 1:(4 + instance.U)) for k = 1:K) >= 0)
                end
            end
        end

        # Pas plus de 4 fournisseurs par camion
        for i = 1:size(clusters, 1)
            for j = 1:instance.J
                for k = 1:K
                    @constraint(model, sum(sum(d[i, j, k, a, b] for a = 1:(4 + instance.U)) for b = 1:(4 + instance.U)) <= 4)
                end
            end
        end


        for i = 1:size(clusters, 1)
            for j = 1:instance.J
                for k = 1:K
                    for a = 1:(4 + instance.U)
                        for b = 1(4 + instance.U)
                            @constraint(model, x[i, j, k, a, b] >= 0)
                        end
                    end
                end
            end
        end
        
        println("CONSTRAINTS OK")

        @objective(
            model,
            Min,
            sum(
                sum(
                    sum(sum(sum(d[i, j, k, 4 + u, f] * (instance.γ * instance.graphe.d[instance.usines[u].v, instance.fournisseurs[clusters[i][f]].v] + instance.cstop) for u = 1:instance.U) for f = 1:size(clusters[i], 1)) for k = 1:K)
                    +
                    sum(sum(sum(d[i, j, k, f1, f2] * (instance.γ * instance.graphe.d[instance.fournisseurs[clusters[i][f1]].v, instance.fournisseurs[clusters[i][f2]].v] + instance.cstop) for f1 = 1:size(clusters[i], 1)) for f2 = 1:size(clusters[i], 1)) for k = 1:K)
                    +
                    sum(instance.usines[u].cs[e] * (s1[i, j, u + 4] - instance.usines[u].r[e, j]) for u = 1:instance.U)
                    +
                    sum(instance.fournisseurs[clusters[i][f]].cs[e] * (s1[i, j, f] - instance.fournisseurs[clusters[i][f]].r[e, j])
                    + instance.fournisseurs[clusters[i][f]].cexc[e] * (s2[i, j, f] - s[i, j, f]) for f = 1:size(clusters[i], 1))
                for j = 1:instance.J)
            for i = 1:size(clusters, 1)
            )
        )
    
        println("OBJECTIVE OK")

        JuMP.optimize!(model)
        println(size(x))

        for j = 1:instance.J
            for i = 1:size(clusters, 1)
                for a = 1:size(x, 4)
                    for b = 1:size(x, 5)
                        for k = 1:K
                            sol_clusters[e, i, j, k, a, b] = JuMP.value(x[i, j, k, a, b])
                        end
                    end
                end
            end
        end
        val += JuMP.objective_value(model)
    end
    println("SOLUTION : ")
    println(val)
    return sol_clusters
end

