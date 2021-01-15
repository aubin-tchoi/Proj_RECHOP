using JuMP, Gurobi

include("dimensions.jl")
include("emballage.jl")
include("usine.jl")
include("fournisseur.jl")
include("graphe.jl")
include("instance.jl")
include("route.jl")

#= On écrit le PLNE pour un jour et un couple (u, f) =#
function solveDispatchSmall(instance::Instance, flow::Array{Float64, 4}, j::Int, u::Int, f::Int, timeLimit::Int)

    model = Model(with_optimizer(Gurobi.Optimizer,  TimeLimit = timeLimit))

    #= Nombre max de camions dont on pourrait avoir besoin (+ 1 pour avoir au moins 1 camion)
    ici on prend les emballages séparés donc on aura potentiellement 1 camion quasi vide par emballage =#
    K = floor(Int64, (sum(instance.emballages[e].l * flow[e, j, u, f] for e = 1:instance.E) + 1) / instance.L) + instance.E

    #= x[k, e] nombre d'emballage e transportés par le camion k
       d[k] == 1 ssi le camion k est utilisé =#
    @variable(model, x[1:K, 1:instance.E] >= 0, Int)
    @variable(model, d[1:K], Bin)

    #= McCormick pour linéariser le produit sum(x[k, :]) * d = sum(x)
    pas besoin d'imposer x = 0 => d = 0 puisque l'on minimise une fontion croissante de d =#
    for k = 1:K
        @constraint(model, sum(x[k, :]) <= instance.E * instance.L * instance.emballages[2].l * d[k])
        @constraint(model, sum(x[k, :]) >= d[k])
    end

    # La demande doit être satisfaite
    for e = 1:instance.E
        @constraint(model, sum(x[:, e]) == flow[e, j, u, f])
    end

    # Chargement
    for k = 1:K
        @constraint(model, sum(instance.emballages[e].l * x[k, e] for e = 1:instance.E) <= instance.L)
    end

    #= Fonction objectif
    on prend ici un coût fixe égal à 1 par camion,
    ce coût vaut en fait ccam + cstop + gamma * d(u, f) mais il est le même pour tous les camions =#
    @objective(model, Min, sum(d[:]))

    JuMP.optimize!(model)

    return JuMP.value.(x)
end

#= On loop sur les jours et les couples (u, f) pour résoudre des PLNE indépendants =#
function solveDispatch(instance::Instance, flow::Array{Float64, 4}, timeLimit::Int)

    # On écrit les solutions du PLNE dans un Array de dimension 3 (1 élément : solution d'1 PLNE (Array de dimension 2))
    dispatch = Array{Array{Int, 2}, 3}(undef, instance.J, instance.U, instance.F)

    for j = 1:instance.J
        for u = 1:instance.U
            for f = 1:instance.F
                if sum(flow[:, j, u, f]) >= 1
                    # On résoud le PLNE qui répartit les emballages dans des camions pour chaque couple (u, f) et pour chaque jour
                    dispatch[j, u, f] = solveDispatchSmall(instance, flow, j, u, f, timeLimit)
                else
                    dispatch[j, u, f] =  Array{Int}(undef, 0, 2)
                end
            end
        end
    end
    return dispatch
end
