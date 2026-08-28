using Bonito
using Observables
using CytoscapeJS

elements = [
    (; data = (; id = "a", label = "A")),
    (; data = (; id = "b", label = "B")),
    (; data = (; id = "ab", source = "a", target = "b")),
]

stylesheet = [
    (; selector = "node", style = Dict(
        "label" => "data(label)",
        "background-color" => "#3b82f6",
    )),
    (; selector = "edge", style = Dict(
        "width" => 2,
        "target-arrow-shape" => "triangle",
        "curve-style" => "bezier",
    )),
]

graph = Cytoscape(elements; stylesheet)

on(ids -> @info("selected", ids), graph.selection)
on(id -> @info("hovered", id), graph.hovered)
on(positions -> @info("positions", positions), graph.positions)

display(App(graph))
