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
    currentSol = solution
    rCurrent = 1
    for r = 1:size(solution.routes)
        initialCost = cost(currentSol, instance)
        backup = currentSol
        deleteat!(currentSol, r)
        if cost(currentSol, instance) > initialCost
            rCurrent  = rCurrent + 1
            currentSol = backup
        end
    end
    return currentSol
end


#= Combine les routes d'une solution pour les parcourir avec un même camion =#
function combineTrucks(instance::Instance, solution::Solution)::Solution
end