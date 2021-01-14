# Main 

include("dimensions.jl")
include("emballage.jl")
include("usine.jl")
include("fournisseur.jl")
include("graphe.jl")
include("instance.jl")
include("route.jl")
include("solution.jl")
include("write.jl")
include("flow.jl")
include("dispatch.jl")
include("upgrade.jl")
include("../code_Julia/cost.jl")

#= Ouverture de l'instance (pas plus d'une minute) =#
instance = lire_instance("Work/instances/espagne.csv")
timerFlow = 1500          # exprimé en secondes
timerDispatch = 50       # exprimé en secondes
notAlreadyWritten = true

if notAlreadyWritten
    #= flow est un array de dimension 4 : e, j, u, f
        flow[e, j, u, f] : combien l'usine u doit fournir au fournisseur f en emballage e le jour j =#
    flow = solveFlow(instance, timerFlow, false)
    println("Flow done")

    #= On doit maintenant résoudre un PLNE pour chaque triplet (j, u, f) qui permettra de trouver
        le nombre de camions nécessaires et la répartition des chargements dans ces camions
        dispatch[j, u, f] : matrice [camion, quantité] transportée pour le jour j depuis l'usine u vers le fournisseur f =#
    dispatch = solveDispatch(instance, flow, timerDispatch)
    println("Dispatch done")

    #= On écrit la solution dans le format demandé (classe Solution) =#
    sol = formatSolution(instance, dispatch)
    println("Solution formatted")

    println("Total cost :")
    println(cost(sol, instance))

    #= On écrit la solution dans le fichier texte solution.txt =#
    write_sol_to_file(sol, "solution.txt")

else
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

    writeCost(instance, lire_solution("solution.txt"), "totalCost.txt")
end

