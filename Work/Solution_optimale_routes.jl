####################### Fonction préliminaire: pour résolution optimale petits pblm ##############
using JuMP, Gurobi

function Solution_Optimale(instance::Instance)
    model = Model(Gurobi.Optimizer)

    @variable(model, Routes_matrix[1:Nbr_routes, 1:instance.U+instance.F], Bin)

    for i = 1:Nbr_routes
        @constraint(model, sum(Routes_matrix[i, j] for j = 1:instance.U) == 1)
    end

    for i = 1:Nbr_routes
        @constraint(
            model,
            sum(Routes_matrix[i, j] for j = instance.U+1:instance.U+instance.F) <= 4
        )
        @constraint(
            model,
            sum(Routes_matrix[i, j] for j = instance.U+1:instance.U+instance.F) >= 1
        )
    end

    for j = instance.U+1:instance.U+instance.F
        @constraint(model, sum(Routes_matrix[i, j] for i = 1:Nbr_routes) >= 1)
    end


    @objective(
        model,
        Min,
        sum(
            first(
                transpose(vcat(Routes_matrix[i, 1:instance.U], zeros(instance.F, 1))) *
                instance.graphe.d *
                vcat(
                    zeros(instance.U, 1),
                    Routes_matrix[i, instance.U+1:instance.U+instance.F],
                ),
            ) for i = 1:Nbr_routes
        )
    )

    JuMP.optimize!(model)

    for i = 1:Nbr_routes
        for j = 1:instance.U+instance.F
            Ensemble_Routes_matrix[i, j] = JuMP.value(Routes_matrix[i, j])
        end
    end


    return JuMP.objective_value(model)
    print(" ")
end
##############################################################################################


include("dimensions.jl")
include("emballage.jl")
include("usine.jl")
include("fournisseur.jl")
include("graphe.jl")
include("instance.jl")
include("route.jl")
include("solution.jl")
include("write.jl")

########################## Instance ###########################################################
instance = lire_instance(joinpath("..", "TOUT", "maroc.csv"))

Base.show(instance)
##############################################################################################

########################## Variables ###########################################################
global Nbr_routes = 3  #min = instance.F/4
global Ensemble_Routes_matrix = zeros(Nbr_routes, instance.U + instance.F)
##############################################################################################

########################## Initialisation ###########################################################
##############################################################################################

########################## HEURISTIQUE ##########################################################
#Création de clusters
println(Solution_Optimale(instance))
println(Ensemble_Routes_matrix)
