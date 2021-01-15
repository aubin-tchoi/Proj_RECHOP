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
include("feasibility.jl")
include("cost.jl")
include("flow.jl")
include("dispatch.jl")
include("upgrade.jl")
include("format.jl")

#= Ouverture de l'instance (pas plus d'une minute) =#
instance = lire_instance("Work/instances/europe.csv")

# Variables globales
timerFlow = 100000          # Exprimé en secondes
timerDispatch = 100         # Exprimé en secondes
numberUpgrades = 10         # Nombre d'améliorations locales
createNewSolution = true
firstText = "solution.txt"
secondText = "solution2.txt"

sol = Solution(R = 1, routes = Array{Route, 1}(undef, 0))

if createNewSolution
    #= flow est un array de dimension 4 : e, j, u, f
        flow[e, j, u, f] : combien l'usine u doit fournir au fournisseur f en emballage e le jour j =#
    flow = solveFlow(instance, timerFlow, true)
    println("Flow done")

    #= On doit maintenant résoudre un PLNE pour chaque triplet (j, u, f) qui permettra de trouver
        le nombre de camions nécessaires et la répartition des chargements dans ces camions
        dispatch[j, u, f] : matrice [camion, quantité] transportée pour le jour j depuis l'usine u vers le fournisseur f =#
    dispatch = solveDispatch(instance, flow, timerDispatch)
    println("Dispatch done")

    #= On écrit la solution dans le format demandé (classe Solution) =#
    global sol = formatSolution(instance, dispatch)
    println("Solution formatted")

    println("Total cost :")
    println(cost(sol, instance))

    #= On écrit la solution dans le fichier texte solution.txt =#
    write_sol_to_file(sol, firstText)
    println(feasibility(sol, instance))

else
    global sol = lire_solution(firstText)
end

for iteration = 1:numberUpgrades
    global sol = removeTruck(instance, sol, 5)
    global sol = combineTrucks(instance, sol, 50)
    println(feasibility(sol, instance))
    writeCost(instance, sol, "totalCost.txt")
    write_sol_to_file(sol, secondText)
end