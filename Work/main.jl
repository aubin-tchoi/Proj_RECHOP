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
include("../code_Julia/cost.jl")

instance = lire_instance("Work/instances/maroc.csv")
timerFlow = 45          # exprimé en secondes
timerDispatch = 5       # exprimé en secondes

#= flow est un array de dimension 4 : e, j, u, f
    flow[e, j, u, f] : combien l'usine u doit fournir au fournisseur f en emballage e le jour j =#
flow = solveFlow(instance, timerFlow)
println("Flow done")

#= On doit maintenant résoudre un PLNE pour chaque triplet (j, u, f) qui permettra de trouver
    le nombre de camions nécessaires et la répartition des chargements dans ces camions
    dispatch[j, u, f] : matrice [camion, quantité] transportée pour le jour j depuis l'usine u vers le fournisseur f =#
dispatch = solveDispatch(instance, flow, timerDispatch)
println("Dispatch done")

sol = formatSolution(instance, dispatch)
println("Solution formatted")

println("Total cost :")
println(cost(sol, instance))