using JuMP, Gurobi

function plne(instance::Instance, clusters::Vector{Int})
    for e = 1:instance.E
        model = Model(Gurobi.Optimizer)

        #= On sépare par clusters i, ensuite la 1ère coord correspond au jour, la 2e au départ et la 3e à la destination
        Dans le départ et la destination on met les 4 fournisseurs en premiers, suivi des instance.U usines
        (d[i][j, 1, 2]) == 1 si dans le cluster i un camion va du 1er fournisseur au 2e =#

        for i = 1:size(clusters, 1)
            @variable(model, d[i][1:instance.J, 1:(4 + instance.U), 1:(4 + instance.U)], Bin)
            @variable(model, x[i][1:instance.J, 1:(4 + instance.U), 1:(4 + instance.U)], Int)
            @variable(model, s[i][1:instance.J, 1:(4 + instance.U)], Int)
            @variable(model, s1[i][1:instance.J, 1:(4 + instance.U)], Int)
            @variable(model, s2[i][1:instance.J, 1:(4 + instance.U)], Int)
        end

        for i = 1:size(clusters, 1)
            for j = 1:instance.J
                for a = 1:(instance.J + 4)
                    for b = 1:(instance.J + 4)
                        @constraint(model, x[i][j, a, b] <= instance.L * d[i][j, a, b])
                        @constraint(model, x[i][j, a, b] >= d[i][j, a, b])
                        @constraint(model, x[i][j, a, b] >= 0)
                    end
                end
            end
        end

        @objective(
            model,
            Min,
            sum(
                sum(
                    sum(sum(d[i][j, a, b] * (instance.γ * instance.graphe.d[] + instance.cstop)) for a = 1:(4 + instance.U)) for b = 1:(4 + instance.U)
                    +
                    sum(instance.usines[u - 4].cs[e] * (s1[i][j, u] - instance.usines[u - 4].r[e, j])) for u = 5:(4 + instance.U)
                    +
                    sum(instance.fournisseurs[].cs[e] * (s1[i][j, f] - instance.fournisseurs[].r[e, j])
                    + instance.fournisseurs[].cexc[e] * (s2[i][j, f] - s[i][j, f])) for f = 1:4
                ) for j = 1:instance.J
            ) for i = 1:size(clusters, 1)
        )

        JuMP.optimize!(model)

        for i = 1:Nbr_routes
            for j = 1:instance.U+instance.F
                sol_clusters[i, j]
            end
        end
    end

end


include("dimensions.jl")
include("emballage.jl")
include("usine.jl")
include("fournisseur.jl")
include("graphe.jl")
include("instance.jl")
include("route.jl")
include("solution.jl")
include("write.jl")

instance = lire_instance("instances/europe.csv")

global sol_clusters = zeros(instance.E, n_clusters, instance.J, (4 + instance.U), (4 + instance.U))