module CytoscapeJS

using Observables: Observable
using Bonito
using Bonito: DOM, Session, onjs, onload, @js_str

export Cytoscape, fit!, center!, run_layout!, set_filter!

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
    filters::Observable{Dict{String, Any}}
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

function set_filter!(graph::Cytoscape, field, value)
    filters = copy(graph.filters[])
    if value === nothing
        delete!(filters, string(field))
    else
        filters[string(field)] = value
    end
    graph.filters[] = filters
    return graph
end

function Bonito.jsrender(session::Session, graph::Cytoscape)
    container = DOM.div(; graph.attributes...)
    onload(session, container, js"""
        async function (container) {
            const selection = $(graph.selection);
            const hovered = $(graph.hovered);
            const positionState = $(graph.positions);
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
            const filters = new Map(Object.entries($(graph.filters[])));
            const applyFilters = elements => {
                elements.forEach(element => {
                    for (const [field, value] of filters) {
                        const variant = element.data("variants")?.[field]?.[value];
                        if (variant) element.data(variant);
                    }
                    const filtered = [...filters].some(([field, value]) => {
                        const fieldValue = element.data(field);
                        if (fieldValue == null) return false;
                        if (Array.isArray(fieldValue)) {
                            return fieldValue.length > 0 && !fieldValue.includes(value);
                        }
                        return fieldValue !== value;
                    });
                    element.toggleClass("filtered", filtered);
                });
            };
            cy.scratch("filters", filters);
            cy.scratch("applyFilters", applyFilters);
            cy.on("add", event => applyFilters(event.target));
            applyFilters(cy.elements());
            const setup = $(graph.setup)
            if (setup) await setup(cy)
            container.cy = cy
            container.layout = $(graph.layout[]);
            const initiallySelected = new Set($(graph.selection[]));
            cy.elements().forEach(element => {
                if (initiallySelected.has(element.id())) element.select();
            });
            const { attachTooltip } = await $(tooltip_asset);
            const disposeTooltip = attachTooltip(
                cy,
                $(graph.tooltip_attributes),
            );
            const observer = new MutationObserver(() => {
                if (container.isConnected) return;

                observer.disconnect();
                disposeTooltip();
                if (!cy.destroyed()) cy.destroy();
            });
            observer.observe(document.documentElement, {
                childList: true,
                subtree: true,
            });
            cy.on("destroy", () => observer.disconnect());
            let selectionPending = false;
            cy.on("select unselect", "node, edge", () => {
                if (container.syncingSelection) return;
                if (selectionPending) return;

                selectionPending = true;
                queueMicrotask(() => {
                    selectionPending = false;
                    if (cy.destroyed()) return;
                    selection.notify(
                        cy.elements(":selected").map(element => element.id())
                    );
                });
            });
            cy.on("mouseover", "node, edge", event => {
                hovered.notify(event.target.id())
            });
            cy.on("mouseout", "node, edge", () => {
                hovered.notify(null);
            });
            const sendPositions = () => {
                if (!container.isConnected || cy.destroyed()) return;
                const positions = {};
                cy.nodes().forEach(node => {
                    positions[node.id()] = node.position();
                })
                positionState.notify(positions);
            }
            cy.on("dragfree", "node", sendPositions);
            cy.on("layoutstop", sendPositions);
            cy.ready(sendPositions);
        }
    """)

    onjs(session, graph.elements, js"""
        elements => {
            const container = $(container);
            if (!container) return false;
            const cy = container.cy;
            if (!cy) return;
            cy.elements().remove()
            cy.add(elements);
            cy.layout(container.layout).run()
        }
    """)
    onjs(session, graph.stylesheet, js"""
        stylesheet => {
            const container = $(container);
            if (!container) return false;
            const cy = container.cy;
            if (!cy) return;
            cy.style().fromJson(stylesheet).update();
        }
    """)
    onjs(session, graph.layout, js"""
        layout => {
            const container = $(container)
            if (!container) return false;
            if (!container.cy) return;
            container.layout = layout;
            container.cy.layout(layout).run();
        }
    """)
    onjs(session, graph.positions, js"""
        positions => {
            const container = $(container);
            if (!container) return false;
            const cy = container.cy;
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
    onjs(session, graph.filters, js"""
        values => {
            const container = $(container);
            if (!container) return false;
            const cy = container.cy;
            if (!cy) return;
            const filters = cy.scratch("filters");
            filters.clear();
            Object.entries(values).forEach(([field, value]) => {
                filters.set(field, value);
            });
            cy.batch(() => cy.scratch("applyFilters")(cy.elements()));
            cy.emit("filter");
        }
    """)
    onjs(session, graph.commands, js"""
        command => {
            const container = $(container);
            if (!container) return false;
            const cy = container.cy
            if (!cy || !command) return;
            const actions = {
                fit: () => cy.fit(undefined, command.padding),
                center: () => cy.center(),
                layout: () => cy.layout(command.layout).run(),
            };
            actions[command.action]?.();
        }
    """)
    onjs(session, graph.selection, js"""
        ids => {
            const container = $(container);
            if (!container) return false;
            const cy = container.cy;
            if (!cy) return;

            const selected = new Set(ids);

            container.syncingSelection = true;
            cy.batch(() => {
                cy.elements().forEach(element => {
                    const shouldSelect = selected.has(element.id());
                    if (shouldSelect !== element.selected()) {
                        shouldSelect ? element.select() : element.unselect();
                    }
                });
            });
            container.syncingSelection = false;
        }
    """)
    return container
end

end
