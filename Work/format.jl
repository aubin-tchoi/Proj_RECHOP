include("dimensions.jl")
include("emballage.jl")
include("usine.jl")
include("fournisseur.jl")
include("graphe.jl")
include("instance.jl")
include("route.jl")
include("solution.jl")
include("write.jl")

#= true si le camion k est utilisé le jour j entre u et f =#
function isUsed(dispatch::Array{Array{Int, 2}, 3}, j, u, f, k)
    for e = 1:instance.E
        if dispatch[j, u, f][k, e] > 0
            return true
        end
    end
    return false
end

#= On transforme l'array dispatch en une instance de Solution pour pouvoir utiliser les fonctions déjà codées =#
function formatSolution(instance::Instance, dispatch::Array{Array{Int, 2}, 3})::Solution
    r = 1
    routes = Route[]
    for j = 1:instance.J
        for u = 1:instance.U
            for f = 1:instance.F
                for k = 1:size(dispatch[j, u, f], 1)
                    if isUsed(dispatch, j, u, f, k)
                        Q = Int[]
                        for e = 1:instance.E
                            push!(Q, dispatch[j, u, f][k, e])
                        end
                        stops = [RouteStop(f = f, Q = Q)]
                        push!(routes, Route(r = r, j = j, x = 1, u = u, F = 1, stops = stops))
                        r = r + 1
                    end
                end
            end
        end 
    end
    return Solution(R = size(routes, 1), routes = routes)
end

#= On note la répartition des différents coûts dans un fichier texte =# 
function writeCost(instance::Instance, solution::Solution, path::String)
    open(path, "w") do file
        U, F, J = instance.U, instance.F, instance.J
        usines, fournisseurs = instance.usines, instance.fournisseurs

        su, sf = compute_stocks(solution, instance)

        c = 0.0
        cu = 0.0
        cf = 0.0
        cr = 0.0

        for u = 1:U
            cc = cost(usines[u], su[:, u, :])
            cu += cc
            c += cc
        end
        write(file, "Coût usine : \n")
        write(file, string(cu))
        write(file, "\n")

        for f = 1:F
            cc = cost(fournisseurs[f], sf[:, f, :])
            cf += cc
            c += cc
        end
        write(file, "Coût fournisseurs : \n")
        write(file, string(cf))
        write(file, "\n")

        for route in solution.routes
            cc = cost(route, instance)
            cr += cc
            c += cc
        end
        
        write(file, "Coût routes : \n")
        write(file, string(cr))
        write(file, "\n")

        write(file, "Coût total : \n")
        write(file,  string(c))
    end
end