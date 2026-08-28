using Bonito
using CytoscapeJS

elements = [
    (; data = (; id = "gene1", label = "Gene 1")),
    (; data = (; id = "mrna1", label = "mRNA", parent = "gene1")),
    (; data = (; id = "protein1", label = "Protein", parent = "gene1")),

    (; data = (; id = "gene2", label = "Gene 2")),
    (; data = (; id = "mrna2", label = "mRNA", parent = "gene2")),
    (; data = (; id = "protein2", label = "Protein", parent = "gene2")),

    (; data = (; id = "translation1", source = "mrna1", target = "protein1")),
    (; data = (; id = "regulation", source = "protein1", target = "gene2")),
    (; data = (; id = "translation2", source = "mrna2", target = "protein2")),
]

stylesheet = [
    (; selector = "node", style = Dict(
        "label" => "data(label)",
        "color" => "#3b82f6",
    )),
    (; selector = ":parent", style = Dict(
        "background-opacity" => 0.15,
        "border-width" => 2,
        "border-color" => "#64748b",
        "padding" => "24px",
        "text-valign" => "top",
    )),
    (; selector = "edge", style = Dict(
        "width" => 2,
        "curve-style" => "bezier",
        "target-arrow-shape" => "triangle",
    )),
]

graph = Cytoscape(elements; stylesheet)

display(App(graph))
