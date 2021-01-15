# Amélioration locale d'une solution admissible

include("dimensions.jl")
include("emballage.jl")
include("usine.jl")
include("fournisseur.jl")
include("instance.jl")
include("route.jl")
include("solution.jl")
include("cost.jl")

#= Retire les routes inutiles d'une solution =#
function removeTruck(instance::Instance, solution::Solution, nIter::Int)::Solution
    println("Removing roads..")

    # Initialisation d'une instance de Solution
    currentSol = deepcopy(solution)
    rCurrent = 1

    # Initialisation des coûts
    newCost = cost(currentSol, instance)
    initialCost = newCost

    for i = 1:size(solution.routes, 1)
        # On autorise au max nIter itérations
        if i > nIter
            break
        end
        # On choisit une route aléatoirement
        r = rand(1:(size(solution.routes, 1) - i))

        # On crée ici un backup pour y revenir si la modification n'est pas profitable
        backup = deepcopy(currentSol)

        # On modifie la solution & on calcule le nouveau coût
        deleteat!(currentSol.routes, rCurrent)
        newCost = cost(currentSol, instance)

        println("Costs :")
        print("Initial cost :")
        println(initialCost)
        print("New cost :")
        println(newCost)

        # On compare les coûts
        if  newCost > initialCost
            println("Modification rejected")
            rCurrent  = rCurrent + 1
            # On retourne en arrière si la modification n'est pas profitable
            currentSol = deepcopy(backup)
        else
            print("Modification accepted, gap :")
            println(newCost - initialCost)
            # L'ancien coût devient le nouveau; on adopte la modification
            initialCost = newCost
            # On met à jour le nombre total de routes
            currentSol.R = currentSol.R - 1
            # On met à jour les indices des routes
            for rc = r:size(currentSol.routes, 1)
                currentSol.routes[rc].r = currentSol.routes[rc].r - 1
            end
        end
    end
    return currentSol
end


#= Combine les routes d'une solution pour les parcourir avec un même camion =#
function combineTrucks(instance::Instance, solution::Solution, nIter::Int)::Solution
    println("Combining roads..")

    # Initialisation d'une instance de Solution
    currentSol = deepcopy(solution)
    rCurrent = 1
    iteration = 1

    # Initialisation des coûts
    newCost = cost(currentSol, instance)
    initialCost = newCost

    for r1 = 1:(size(solution.routes, 1) - 1)
        for r2 = (r1 + 1):(size(solution.routes, 1) - 1)
            if iteration > nIter
                break
            end
            iteration = iteration + 1

            # On choisit 2 routes aléatoirement
            r1 = rand(1:(size(solution.routes, 1)) - iteration)
            r2 = rand(1:(size(solution.routes, 1)) - iteration)

            # On crée ici un backup pour y revenir si la modification n'est pas profitable
            backup = deepcopy(currentSol)

            # On modifie la solution si la route ne comporte pas déjà 4 arrêts
            if currentSol.routes[r1].F <= 4
                # On combine les deux routes
                currentSol.routes[r1].F = currentSol.routes[r1].F + 1 # On a ajouté un arrêt
                push!(currentSol.routes[r1].stops, currentSol.routes[r2].stops[1])
                deleteat!(currentSol.routes, rCurrent)

                newCost = cost(currentSol, instance)

                println("Costs :")
                print("Initial cost :")
                println(initialCost)
                print("New cost :")
                println(newCost)

                # On compare les coûts
                if  newCost > initialCost
                    println("Modification rejected")
                    rCurrent  = rCurrent + 1
                    # On repart en arrière si la modification n'est pas profitable
                    currentSol = deepcopy(backup)
                else
                    print("Modification accepted, gap :")
                    println(newCost - initialCost)
                    # On adopte les modifications, on a avancé d'un pas dans la recherche du min local
                    initialCost = newCost
                    # On met à jour le nombre total de routes
                    currentSol.R = currentSol.R - 1
                    # On met à jour les indices des routes
                    for rc = r2:size(currentSol.routes, 1)
                        currentSol.routes[rc].r = currentSol.routes[rc].r - 1
                    end
                end
            end
        end
    end
    return currentSol
end