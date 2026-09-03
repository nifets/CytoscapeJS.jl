using Bonito
using Bonito: DOM, onload, @js_str
using CytoscapeJS

elements = [
    (; data = (; id = "a", label = "A")),
    (; data = (; id = "b", label = "B")),
    (; data = (; id = "c", label = "C")),
    (; data = (; id = "ab", source = "a", target = "b")),
    (; data = (; id = "bc", source = "b", target = "c")),
]

stylesheet = [
    (; selector = "node", style = Dict(
        "label" => "data(label)",
        "color" => "#3b82f6",
    )),
    (; selector = "node:selected", style = Dict(
        "background-color" => "#ef4444",
    )),
    (; selector = "edge", style = Dict(
        "width" => 2,
        "target-arrow-shape" => "triangle",
        "curve-style" => "bezier",
    )),
]

app = App() do session
    graph = Cytoscape(elements; stylesheet, attributes=(; style="height: 400px"))
    readout = DOM.span("nothing selected")
    clear = DOM.button("clear")
    container = DOM.div(graph, DOM.div(readout, clear))

    onload(session, container, js"""
        container => {
            const graph = container.querySelector("div");

            container.addEventListener("cytoscape:selection", event => {
                const ids = event.detail.selection;
                container.querySelector("span").textContent =
                    ids.length ? `selected: ${ids.join(", ")}` : "nothing selected";
            });

            container.querySelector("button").addEventListener("click", () => {
                graph.cytoscape.selection.set([]);
            });
        }
    """)

    container
end

display(app)
