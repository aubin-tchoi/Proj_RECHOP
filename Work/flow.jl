using JuMP, Gurobi

include("dimensions.jl")
include("emballage.jl")
include("usine.jl")
include("fournisseur.jl")
include("graphe.jl")
include("instance.jl")
include("route.jl")
include("solution.jl")
include("write.jl")

function solveFlowAllE(instance::Instance, timeLimit::Int, isInteger::Bool)

    model = Model(with_optimizer(Gurobi.Optimizer,  TimeLimit = timeLimit))

    # x correspond à la quantité transportée, su au stock usine et sf au stock fournisseur
    @variable(model, x[1:instance.E, 1:instance.J, 1:instance.U, 1:instance.F] >= 0, integer = isInteger)
    @variable(model, su[1:instance.E, 1:instance.U, 1:instance.J] >= 0, integer = isInteger)
    @variable(model, sf[1:instance.E, 1:instance.F, 1:instance.J], integer = isInteger)

    # su', sf', sf" pour linéariser les max
    @variable(model, su1[1:instance.E, 1:instance.U, 1:instance.J])
    @variable(model, sf1[1:instance.E, 1:instance.F, 1:instance.J])
    @variable(model, sf2[1:instance.E, 1:instance.F, 1:instance.J])

    # Évolution du stock usine
    for e = 1:instance.E
        for u = 1:instance.U
            @constraint(model, su[e, u, 1] == instance.usines[u].s0[e] + instance.usines[u].b⁺[e, 1] - sum(x[e, 1, u, :]))
            for j = 2:instance.J
                @constraint(model, su[e, u, j] == su[e, u, j - 1] + instance.usines[u].b⁺[e, j] - sum(x[e, j, u, :]))
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
        for f = 1:instance.F
            @constraint(model, sf[e, f, 1] == instance.fournisseurs[f].s0[e] + sum(x[e, 1, :, f]) - instance.fournisseurs[f].b⁻[e, 1])
            for j = 2:instance.J
                @constraint(model, sf[e, f, j] - sum(x[e, j, :, f]) >= sf[e, f, j - 1] - instance.fournisseurs[f].b⁻[e, j])
                @constraint(model, sf[e, f, j] - sum(x[e, j, :, f]) >= 0)
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

    # Fonction objectif (coût route, coût stock excédentaire usine, coût stock excédentaire/déficitaire fournisseur)
    @objective(model, Min,
        sum((x[e, j, u, f] * instance.emballages[e].l / instance.L) * instance.γ * instance.graphe.d[instance.usines[u].v, instance.fournisseurs[f].v]
                        for f in 1:instance.F, u in 1:instance.U, j in 1:instance.J, e in 1:instance.E)
        +
        sum(instance.usines[u].cs[e] * su1[e, u, j]
                    for j in 1:instance.J, u in 1:instance.U, e in 1:instance.E)
        +
        sum(instance.fournisseurs[f].cs[e] * (sf1[e, f, j] - instance.fournisseurs[f].r[e, j]) for f in 1:instance.F, j in 1:instance.J, e in 1:instance.E)
        +
        sum(instance.fournisseurs[f].cexc[e] * (sf2[e, f, j] - sf[e, f, j])
                    for f in 1:instance.F, j in 1:(instance.J - 1), e in 1:instance.E)
        )

    JuMP.optimize!(model)

    return JuMP.value.(x)
end


function solveFlow(instance::Instance, timeLimit::Int, isInteger::Bool)

    flowSol = Array{Float64, 4}(undef, instance.E, instance.J, instance.U, instance.F)

    for e = 1:instance.E

        model = Model(with_optimizer(Gurobi.Optimizer,  TimeLimit = timeLimit))

        # x correspond à la quantité transportée, su au stock usine et sf au stock fournisseur
        @variable(model, x[1:instance.J, 1:instance.U, 1:instance.F] >= 0, integer = isInteger)
        @variable(model, su[1:instance.U, 1:instance.J] >= 0, integer = isInteger)
        @variable(model, sf[1:instance.F, 1:instance.J] >= 0, integer = isInteger)
        @variable(model, k[1:instance.J, 1:instance.U, 1:instance.F] >= 0, integer = false)

        # su', sf', sf" pour linéariser les max
        @variable(model, su1[1:instance.U, 1:instance.J])
        @variable(model, sf1[1:instance.F, 1:instance.J])
        @variable(model, sf2[1:instance.F, 1:instance.J])

        # Nombre de camions
        for u = 1:instance.U
            for j = 1:instance.J
                for f = 1:instance.F
                    @constraint(model, k[j, u, f] >= x[j, u, f] * instance.emballages[e].l / instance.L + 1)
                end
            end
        end

        # Évolution du stock usine
        for u = 1:instance.U
            @constraint(model, su[u, 1] == instance.usines[u].s0[e] + instance.usines[u].b⁺[e, 1] - sum(x[1, u, :]))
            for j = 2:instance.J
                @constraint(model, su[u, j] == su[u, j - 1] + instance.usines[u].b⁺[e, j] - sum(x[j, u, :]))
            end
        end

        # Coût excédentaire usine
        for j = 1:instance.J
            for u = 1:instance.U
                @constraint(model, su1[u, j] >= su[u, j])
                @constraint(model, su1[u, j] >= instance.usines[u].r[e, j])
            end
        end

        # Évolution du stock fournisseur
        for f = 1:instance.F
            @constraint(model, sf[f, 1] == instance.fournisseurs[f].s0[e] + sum(x[1, :, f]) - instance.fournisseurs[f].b⁻[e, 1])
            for j = 2:instance.J
                @constraint(model, sf[f, j] - sum(x[j, :, f]) >= sf[f, j - 1] - instance.fournisseurs[f].b⁻[e, j])
                @constraint(model, sf[f, j] - sum(x[j, :, f]) >= 0)
            end
        end

        # Coût excédentaire/déficit fournisseur
        for j = 1:instance.J
            for f = 1:instance.F
                @constraint(model, sf1[f, j] >= sf[f, j])
                @constraint(model, sf1[f, j] >= instance.fournisseurs[f].r[e, j])
                @constraint(model, sf2[f, j] >= sf[f, j])
                @constraint(model, sf2[f, j] >= instance.fournisseurs[f].b⁻[e, j])
            end
        end

        # Fonction objectif (coût route, coût stock excédentaire usine, coût stock excédentaire/déficitaire fournisseur)
        @objective(model, Min,
            sum(k[j, u, f] * instance.ccam for j in 1:instance.J, u in 1:instance.U, f in 1:instance.F) +
            sum((x[j, u, f] * instance.emballages[e].l / instance.L) * instance.γ * instance.graphe.d[instance.usines[u].v, instance.fournisseurs[f].v]
                            for f in 1:instance.F, u in 1:instance.U, j in 1:instance.J)
            +
            sum(instance.usines[u].cs[e] * su1[u, j]
                        for j in 1:instance.J, u in 1:instance.U)
            +
            sum(instance.fournisseurs[f].cs[e] * (sf1[f, j] - instance.fournisseurs[f].r[e, j]) for f in 1:instance.F, j in 1:instance.J)
            +
            sum(instance.fournisseurs[f].cexc[e] * (sf2[f, j] - sf[f, j])
                        for f in 1:instance.F, j in 1:(instance.J - 1))
            )

        JuMP.optimize!(model)

        for j = 1:instance.J
            for u = 1:instance.U
                for f = 1:instance.F
                    flowSol[e, j, u, f] = JuMP.value.(x[j, u, f])
                end
            end
        end
    end
    return flowSol
end