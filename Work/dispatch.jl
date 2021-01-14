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

#= On écrit le PLNE pour un jour et un couple (u, f) =#
function solveDispatchSmall(instance::Instance, flow::Array{Float64, 4}, j::Int, u::Int, f::Int, timeLimit::Int)

    model = Model(with_optimizer(Gurobi.Optimizer,  TimeLimit = timeLimit))

    #= Nombre max de camions dont on pourrait avoir besoin (+ 1 pour avoir au moins 1 camion)
    ici on prend les emballages séparés donc on aura potentiellement 1 camion quasi vide par emballage =#
    K = sum(floor(Int64, instance.emballages[e].l * flow[e, j, u, f] / instance.L) for e = 1:instance.E) + 1

    #= x[k, e] nombre d'emballage e transportés par le camion k
       d[k] == 1 ssi le camion k est utilisé =#
    @variable(model, x[1:K, 1:instance.E], Int)
    @variable(model, d[1:K], Bin)

    #= McCormick pour linéariser le produit sum(x) * d = sum(x)
    pas besoin d'imposer x = 0 => d = 0 puisque l'on minimise une fontion croissante de d =#
    for k = 1:K
        @constraint(model, sum(x[k, e] for e = 1:instance.E) <= instance.E * instance.L * d[k])
        @constraint(model, sum(x[k, e] for e = 1:instance.E) >= d[k])
        for e = 1:instance.E
            @constraint(model, x[k, e] >= 0)
        end
    end

    # La demande doit être satisfaite
    for e = 1:instance.E
        @constraint(model, sum(x[k, e] for k = 1:K) == flow[e, j, u, f])
    end

    # Chargement
    for k = 1:K
        @constraint(model, sum(instance.emballages[e].l * x[k, e] for e = 1:instance.E) <= instance.L)
    end

    #= Fonction objectif
    on prend ici un coût fixe égal à 1 par camion,
    ce coût vaut en fait ccam + cstop + gamma * d(u, f) mais il est le même pour tous les camions =#
    @objective(model, Min, sum(d[k] for k = 1:K))

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
                # On résoud le PLNE qui répartit les emballages dans des camions pour chaque couple (u, f) et pour chaque jour
                dispatch[j, u, f] = solveDispatchSmall(instance, flow, j, u, f, timeLimit)
            end
        end
    end
    return dispatch
end

#= On transforme l'array dispatch en une instance de Solution pour pouvoir utiliser les fonctions déjà codées =#
function formatSolution(instance::Instance, dispatch::Array{Array{Int, 2}, 3})
    r = 1
    routes = Route[]
    for j = 1:instance.J
        for u = 1:instance.U
            for f = 1:instance.F
                for k = 1:size(dispatch[j, u, f], 1)
                    if sum(dispatch[j, u, f][k, e] for e = 1:instance.E) >= 1
                        Q = Int[]
                        for e = 1:instance.E
                            push!(Q, dispatch[j, u, f][k, e])
                        end
                        stops = [RouteStop(f = f, Q = Q)]
                        push!(routes, Route(r = r, j = j, x = size(dispatch[j, u, f], 1), u = u, F = f, stops = stops))
                        r = r + 1
                    end
                end
            end
        end 
    end
    return Solution(R = size(routes, 1), routes = routes)
end