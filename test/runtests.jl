using Test
using Bonito
using Observables
using CytoscapeJS

elements = [
    (; data = (; id = "a", condition = "control")),
    (; data = (; id = "b", condition = "treated")),
    (; data = (; id = "ab", source = "a", target = "b")),
]

@testset "construction" begin
    graph = Cytoscape(elements)

    @test graph.elements[] == elements

    source = Observable(elements)
    @test Cytoscape(source).elements === source

    @test Cytoscape(elements; wheelSensitivity = 0.5).options.wheelSensitivity == 0.5
end

@testset "commands" begin
    graph = Cytoscape(elements)

    @test fit!(graph) === graph
    @test graph.commands[] == (; action = "fit", padding = 30)

    fit!(graph; padding = 10)
    @test graph.commands[].padding == 10

    center!(graph)
    @test graph.commands[] == (; action = "center")

    run_layout!(graph)
    @test graph.commands[].action == "layout"
    @test graph.commands[].layout == graph.layout[]
end

@testset "filters" begin
    graph = Cytoscape(elements)

    @test set_filter!(graph, :condition, "treated") === graph
    @test graph.filters[] == Dict("condition" => "treated")

    set_filter!(graph, "other", 1)
    @test graph.filters[] == Dict("condition" => "treated", "other" => 1)

    set_filter!(graph, :condition, nothing)
    @test graph.filters[] == Dict("other" => 1)
end

@testset "rendering" begin
    render(graph) = sprint(io -> show(io, MIME"text/html"(), App(graph)))

    @test !isempty(render(Cytoscape(elements)))
    @test !isempty(render(Cytoscape(elements; setup = js"cy => { cy.fit(); }")))
end
