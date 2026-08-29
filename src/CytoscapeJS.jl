module CytoscapeJS

using Observables: Observable
using Bonito
using Bonito: DOM, Session, onjs, onload, @js_str

export Cytoscape, fit!, center!, run_layout!

const cytoscape_asset = Bonito.Asset(
    joinpath(@__DIR__, "..", "assets", "cytoscape.js");
    name = "cytoscape"
)
const tooltip_asset = Bonito.ES6Module(
    joinpath(@__DIR__, "..", "assets", "tooltip.js"),
)

struct Cytoscape{E, S, L, R, F, T, A, O}
    elements::E
    stylesheet::S
    layout::L
    renderer::R
    setup::F
    tooltip_attributes::T
    selection::Observable{Vector{String}}
    hovered::Observable{Union{Nothing, String}}
    positions::Observable{Dict{String, Any}}
    commands::Observable{Any}
    attributes::A
    options::O
end

as_observable(value::Observable) = value
as_observable(value) = Observable(value)

function Cytoscape(
    elements;
    stylesheet = [],
    layout = (; name = "fcose"),
    renderer = (; name = "canvas"),
    setup = nothing,
    tooltip_attributes = (; class="cytoscapejs-tooltip"),
    attributes = (; style = "width: 100%; height: 100%; min-height: 400px"),
    kwargs...
)
    Cytoscape(
        as_observable(elements),
        as_observable(stylesheet),
        as_observable(layout),
        renderer,
        setup,
        tooltip_attributes,
        Observable(String[]),
        Observable{Union{Nothing, String}}(nothing),
        Observable(Dict{String, Any}()),
        Observable{Any}(nothing),
        attributes,
        (;kwargs...)
    )
end

function fit!(graph::Cytoscape; padding=30)
    graph.commands[] = (; action="fit", padding)
    return graph
end

function center!(graph::Cytoscape)
    graph.commands[] = (; action="center")
    return graph
end

function run_layout!(graph::Cytoscape)
    graph.commands[] = (; action="layout", layout=graph.layout[])
    return graph
end

function Bonito.jsrender(session::Session, graph::Cytoscape)
    container = DOM.div(; graph.attributes...)
    onload(session, container, js"""
        async function (container) {
            const cytoscape = await $(cytoscape_asset);
            await document.fonts.ready;

            const cy = cytoscape({
                ...$(graph.options),
                container,
                elements: $(graph.elements[]),
                style: $(graph.stylesheet[]),
                layout: $(graph.layout[]),
                renderer: $(graph.renderer),
            })
            const setup = $(graph.setup)
            if (setup) await setup(cy)
            container.cy = cy
            container.layout = $(graph.layout[]);
            const { attachTooltip } = await $(tooltip_asset);
            attachTooltip(cy, $(graph.tooltip_attributes));
            cy.on("select unselect", "node, edge", () => {
                $(graph.selection).notify(
                    cy.elements(":selected").map(element => element.id())
                )
            });
            cy.on("mouseover", "node, edge", event => {
                $(graph.hovered).notify(event.target.id())
            });
            cy.on("mouseout", "node, edge", () => {
                $(graph.hovered).notify(null);
            });
            const sendPositions = () => {
                const positions = {};
                cy.nodes().forEach(node => {
                    positions[node.id()] = node.position();
                })
                $(graph.positions).notify(positions);
            }
            cy.on("dragfree", "node", sendPositions);
            cy.on("layoutstop", sendPositions);
            cy.ready(sendPositions);
        }
    """)

    onjs(session, graph.elements, js"""
        elements => {
            const cy = $(container).cy;
            if (!cy) return;
            cy.elements().remove()
            cy.add(elements);
            cy.layout($(container).layout).run()
        }
    """)
    onjs(session, graph.stylesheet, js"""
        stylesheet => {
            const cy = $(container).cy;
            if (!cy) return;
            cy.style().fromJson(stylesheet).update();
        }
    """)
    onjs(session, graph.layout, js"""
        layout => {
            const container = $(container)
            if (!container.cy) return;
            container.layout = layout;
            container.cy.layout(layout).run();
        }
    """)
    onjs(session, graph.positions, js"""
        positions => {
            const cy = $(container).cy;
            if (!cy) return
            cy.batch(() => {
                Object.entries(positions).forEach(([id, position]) => {
                    const node = cy.getElementById(id);
                    if (node.nonempty()) {
                        node.position(position);
                    }
                })
            })
        }
    """)
    onjs(session, graph.commands, js"""
        command => {
            const cy = $(container).cy
            if (!cy || !command) return;
            const actions = {
                fit: () => cy.fit(undefined, command.padding),
                center: () => cy.center(),
                layout: () => cy.layout(command.layout).run()
            };
            actions[command.action]?.();
        }
    """)
    return container
end

end
