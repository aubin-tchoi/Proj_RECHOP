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

function solve_flot(instance::Instance, timeLimit::Int)

    model = Model(with_optimizer(Gurobi.Optimizer,  TimeLimit = timeLimit))

    println("Model initialized")

    @variable(model, x[1:instance.E, 1:instance.J, 1:instance.U, 1:instance.F], Int)
    @variable(model, su[1:instance.E, 1:instance.U, 1:instance.J], Int)
    @variable(model, sf[1:instance.E, 1:instance.F, 1:instance.J], Int)
    @variable(model, su1[1:instance.E, 1:instance.U, 1:instance.J], Int)
    @variable(model, sf1[1:instance.E, 1:instance.F, 1:instance.J], Int)
    @variable(model, sf2[1:instance.E, 1:instance.F, 1:instance.J], Int)

    println("Variables initialized")

    # Quantités transportées positives
    for e = 1:instance.E
        for j = 1:instance.J
            for u = 1:instance.U
                for f = 1:instance.F
                    @constraint(model, x[e, j, u, f] >= 0)
                end
            end
        end
    end

    # Stock usine positif
    for e = 1:instance.E
        for u = 1:instance.U
            for j = 1:instance.J
                @constraint(model, su[e, u, j] >= 0)
            end
        end
    end

    # Évolution du stock usine
    for e = 1:instance.E
        for j = 2:instance.J
            for u = 1:instance.U
                @constraint(model, su[e, u, j] == su[e, u, j - 1] + instance.usines[u].b⁺[e, j] - sum(x[e, j, u, f] for f = 1:instance.F))
            end
        end
    end

    # Coût excédentaire usine
    for e = 1:instance.E
        for j = 1:instance.J
            for u = 1:instance.U
                @constraint(model, su1[e, u, j] >= su[e, u, j])
                @constraint(model, su1[e, u, j] >= instance.usines[u].r[e, j])
            end
        end
    end

    # Évolution du stock fournisseur
    for e = 1:instance.E
        for j = 2:instance.J
            for f = 1:instance.F
                @constraint(model, sf[e, f, j] - sum(x[e, j, u, f] for u = 1:instance.U) >= sf[e, f, j - 1] - instance.fournisseurs[f].b⁻[e, j])
                @constraint(model, sf[e, f, j] - sum(x[e, j, u, f] for u = 1:instance.U) >= 0)
            end
        end
    end

    # Coût excédentaire/déficit fournisseur
    for e = 1:instance.E
        for j = 1:instance.J
            for f = 1:instance.F
                @constraint(model, sf1[e, f, j] >= sf[e, f, j])
                @constraint(model, sf1[e, f, j] >= instance.fournisseurs[f].r[e, j])
                @constraint(model, sf2[e, f, j] >= sf[e, f, j])
                @constraint(model, sf2[e, f, j] >= instance.fournisseurs[f].b⁻[e, j])
            end
        end
    end

    println("Constraints initialized")

    # Coût de transport (avec un nombre de camions pas entier)
    function travelCost(x::Array{VariableRef, 4})
        return 
        sum(
            sum(
                sum(
                    sum(x[e, j, u, f] * instance.emballages[e].l / instance.L * instance.γ * instance.graphe.d[instance.usines[u].v, instance.fournisseurs[f].v] for f = 1:instance.F
                    ) for u = 1:instance.U
                ) for j = 1:instance.J
            ) for e = 1:instance.E
        )
    end

    # Coût d'un excédent ou d'un déficit dans un fournisseur
    function excessF(sf::Array{VariableRef, 3}, sf1::Array{VariableRef, 3}, sf2::Array{VariableRef, 3})
        return sum(sum(sum(instance.fournisseurs[f].cs[e] * (sf1[e, f, j] - instance.fournisseurs[f].r[e, j])
        + instance.fournisseurs[f].cexc[e] * (sf2[e, f, j] - sf[e, f, j]) for f = 1:instance.F) for j = 1:instance.J) for e = 1:instance.E)
    end

    # Coût d'un excédent en stock dans une usine
    function excessU(su::Array{VariableRef, 3})
        return sum(sum(sum(instance.usines[u].cs[e] * su[e, u, j] for j = 1:instance.J) for u = 1:instance.U) for e = 1:instance.E)
    end

    # Fonction objectif
    @objective(model, Min,
        sum(
            sum(
                sum(
                    sum(x[e, j, u, f] * instance.emballages[e].l / instance.L * instance.γ * instance.graphe.d[instance.usines[u].v, instance.fournisseurs[f].v] for f = 1:instance.F
                    ) for u = 1:instance.U
                ) for j = 1:instance.J
            ) for e = 1:instance.E
        )
        + sum(sum(sum(instance.usines[u].cs[e] * su1[e, u, j] for j = 1:instance.J) for u = 1:instance.U) for e = 1:instance.E)
        + sum(sum(sum(instance.fournisseurs[f].cs[e] * (sf1[e, f, j] - instance.fournisseurs[f].r[e, j])
        + instance.fournisseurs[f].cexc[e] * (sf2[e, f, j] - sf[e, f, j]) for f = 1:instance.F) for j = 1:instance.J) for e = 1:instance.E))
        + excessU(su1)

    println("Objective initialized")

    JuMP.optimize!(model)

    println("Coût total :")
    println(JuMP.objective_value(model))

    return JuMP.value.(x)
end