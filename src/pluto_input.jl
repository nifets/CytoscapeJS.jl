"""
    PlutoInput(observable; debounce=150)

Expose an `Observable` as a Pluto notebook variable:

```julia
@bind selected CytoscapeJS.PlutoInput(graph.selection)
```

This should really be a general Bonito/Pluto helper, it is not CytoscapeJS specific. Removed once an upstream equivalent exists.
"""
struct PlutoInput{T}
    observable::Observable{T}
    debounce::Int
end

PlutoInput(observable::Observable; debounce = 150) =
    PlutoInput(observable, debounce)

Bonds.initial_value(input::PlutoInput) = input.observable[]

Bonds.transform_value(input::PlutoInput{T}, value) where {T} =
    value isa AbstractVector ? convert(T, value) : input.observable[]

function Base.show(io::IO, mime::MIME"text/html", input::PlutoInput)
    app = App() do session
        anchor = DOM.span(; style = "display: none")
        push = js"""
            (node, value) => {
                if (!node) return false;
                while (node.parentElement && node.parentElement.tagName !== "BOND") {
                    node = node.parentElement;
                }
                if (!node.parentElement) return false;

                node.value = value ?? [];
                clearTimeout(node.plutoInputTimer);
                node.plutoInputTimer = setTimeout(() => {
                    node.dispatchEvent(new CustomEvent("input", { bubbles: true }));
                }, $(input.debounce));
            }
        """
        onload(session, anchor, js"""
            node => ($(push))(node, $(input.observable[]))
        """)
        onjs(session, input.observable, js"""
            value => ($(push))($(anchor), value)
        """)
        anchor
    end
    return show(io, mime, app)
end
