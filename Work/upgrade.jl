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
include("../code_Julia/feasibility.jl")

#= Retire les routes inutiles d'une solution =#
function removeTruck(instance::Instance, solution::Solution, nIter::Int)::Solution
    currentSol = deepcopy(solution)
    rCurrent = 1
    newCost = cost(currentSol, instance)
    for r = 1:size(solution.routes, 1)
        if r > nIter
            break
        end
        initialCost = newCost
        backup = deepcopy(currentSol)
        deleteat!(currentSol.routes, r)
        if feasibility(currentSol, instance)
            nowCost = cost(currentSol, instance)

            println("Costs :")
            print("Initial cost :")
            println(initialCost)
            print("New cost :")
            println(nowCost)

            if  nowCost > initialCost
                println("Modification rejected")
                rCurrent  = rCurrent + 1
                currentSol = deepcopy(backup)
            else
                currentSol.R = currentSol.R - 1
                for rc = r2:size(currentSol.routes, 1)
                    currentSol.routes[rc].r = currentSol.routes[rc].r - 1
            end
        end
    end
    return currentSol
end


#= Combine les routes d'une solution pour les parcourir avec un même camion =#
function combineTrucks(instance::Instance, solution::Solution, nIter::Int)::Solution
    currentSol = deepcopy(solution)
    rCurrent = 1
    newCost = cost(currentSol, instance)
    for r1 = 1:(size(solution.routes, 1) - 1)
        for r2 = (r1 + 1):(size(solution.routes, 1) - 1)
            if r1 * r2  > nIter
                break
            end
            initialCost = newCost
            backup = deepcopy(currentSol)

            currentSol.routes[r1].F = currentSol.routes[r1].F + 1
            push!(currentSol.routes[r1].stops, currentSol.routes[r2].stops[1])
            deleteat!(currentSol.routes, r2)

            if feasibility(currentSol, instance)
                nowCost = cost(currentSol, instance)

                println("Costs :")
                print("Initial cost :")
                println(initialCost)
                print("New cost :")
                println(nowCost)

                if  nowCost > initialCost
                    println("Modification rejected")
                    rCurrent  = rCurrent + 1
                    currentSol = deepcopy(backup)
                else
                    currentSol.R = currentSol.R - 1
                    for rc = r2:size(currentSol.routes, 1)
                        currentSol.routes[rc].r = currentSol.routes[rc].r - 1
                end
            end
        end
    end
    return currentSol
end