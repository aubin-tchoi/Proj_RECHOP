# Amélioration locale d'une solution admissible

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

#= Retire les routes inutiles d'une solution =#
function removeTruck(instance::Instance, solution::Solution)::Solution
    currentSol = Solution(R = solution.R, routes = solution.routes)
    rCurrent = 1
    for r = 1:size(solution.routes, 1)
        initialCost = cost(currentSol, instance)
        backup = Solution(R = currentSol.R, routes = currentSol.routes)
        deleteat!(currentSol.routes, r)
        nowCost = cost(currentSol, instance)

        println("Costs :")
        print("Initial cost :")
        println(initialCost)
        print("New cost :")
        println(nowCost)

        if  nowCost > initialCost
            println("Modification rejected")
            rCurrent  = rCurrent + 1
            currentSol = Solution(R = backup.R, routes = backup.routes)
            println(cost(currentSol, instance) == cost(backup, instance))
        end
    end
    return currentSol
end


#= Combine les routes d'une solution pour les parcourir avec un même camion =#
function combineTrucks(instance::Instance, solution::Solution)::Solution
end