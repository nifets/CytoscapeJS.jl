### A Pluto.jl notebook ###
# v1.0.1

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    #! format: off
    return quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
    #! format: on
end

# ╔═╡ 47982b40-ac33-11f1-9434-81d101dacc2f
begin
	import Pkg
	Pkg.activate(temp=true)
	Pkg.develop(path="..")
	Pkg.add(["Bonito", "PlutoUI"])
	using Bonito, CytoscapeJS, PlutoUI
end;

# ╔═╡ 18d7d997-1ec7-41a8-bece-4f154f415a91
elements = [
	(; data=(; id="a", label="A")),
	(; data=(; id="b", label="B")),
	(; data=(; id="ab", source="a", target="b"))
]

# ╔═╡ 5ed62554-0896-44bc-a75f-f174ffbf216c
stylesheet = [
    (; selector = "node", style = Dict(
        "label" => "data(label)",
        "color" => "#3b82f6",
    )),
    (; selector = "edge", style = Dict(
        "target-arrow-shape" => "triangle",
        "curve-style" => "bezier",
    )),
]

# ╔═╡ b389e3fc-07d3-4712-a0dd-db6b6f6b2b09
graph = Cytoscape(elements; stylesheet)

# ╔═╡ f96be67a-30ce-4636-a28c-b5be0a35e9cf
App(graph)

# ╔═╡ 5ce82fd8-4140-4fd7-92ad-94fecaa3e710
md"""
Two options for handling selection:
1. Without going through Julia at all:
"""

# ╔═╡ 0c6bb067-80d5-41ce-a10d-4a326cbcd5ac
App() do session
    sel = Observable("-")
    on(session, graph.selection) do ids
        sel[] = isempty(ids) ? "-" : join(ids, ", ")
    end

    DOM.p("selected: ", sel)
end

# ╔═╡ 3bec3fda-5fc6-4dde-86bf-341260650f99
md"""
2. Binding it to a Julia variable:
"""

# ╔═╡ 7a080b86-bba9-4a5f-adea-6a3299196cb1
@bind selected CytoscapeJS.PlutoInput(graph.selection)

# ╔═╡ 8e142b7d-50e8-4d7a-a9e7-a96affe67f62
selected

# ╔═╡ 73d3775a-8bc7-4635-956b-511ccaea2ab0
induced_edges = let
	if !isnothing(selected)
		chosen = Set(selected)
		[e.data for e in graph.elements[] if hasproperty(e.data, :source) && (e.data.source in chosen && e.data.target in chosen)]
	end
end

# ╔═╡ a2ef1958-7be1-4da8-ae5f-7836845d93eb
@bind fit PlutoUI.Button("refit graph")

# ╔═╡ 9715f4b5-b9b9-4f04-a3bd-48f2d478fb6f
(fit; fit!(graph));

# ╔═╡ ea79266e-f3e6-4884-968c-fcb8c5493b65
@bind clicks PlutoUI.CounterButton("add node")

# ╔═╡ 32f48399-a3ae-4166-883d-08efab4b0278
let
	if clicks > 0
		node = "n$clicks"
		graph.elements[] = [graph.elements[]...,
			(; data = (; id=node, label=node)),
			(; data = (; id = "a-$node", source="a", target=node))]
	end
end;

# ╔═╡ 9ab5b169-8f80-4207-bd42-605a799bcb00
md"""delete on click: $(@bind delete_on_click PlutoUI.Switch(default=false))"""

# ╔═╡ 6180a47f-eb3a-40f2-b09e-314697001e1c
if delete_on_click && !isempty(selected)
	gone = Set(selected)
	graph.elements[] = filter(graph.elements[]) do element
		d = element.data
		hasproperty(d, :source) ?
			!(d.id in gone) && !(d.source in gone) && !(d.target in gone) :
			!(d.id in gone)
	end
end;

# ╔═╡ Cell order:
# ╠═47982b40-ac33-11f1-9434-81d101dacc2f
# ╠═18d7d997-1ec7-41a8-bece-4f154f415a91
# ╠═5ed62554-0896-44bc-a75f-f174ffbf216c
# ╠═b389e3fc-07d3-4712-a0dd-db6b6f6b2b09
# ╠═f96be67a-30ce-4636-a28c-b5be0a35e9cf
# ╟─5ce82fd8-4140-4fd7-92ad-94fecaa3e710
# ╠═0c6bb067-80d5-41ce-a10d-4a326cbcd5ac
# ╟─3bec3fda-5fc6-4dde-86bf-341260650f99
# ╠═7a080b86-bba9-4a5f-adea-6a3299196cb1
# ╠═8e142b7d-50e8-4d7a-a9e7-a96affe67f62
# ╠═73d3775a-8bc7-4635-956b-511ccaea2ab0
# ╠═a2ef1958-7be1-4da8-ae5f-7836845d93eb
# ╠═9715f4b5-b9b9-4f04-a3bd-48f2d478fb6f
# ╠═ea79266e-f3e6-4884-968c-fcb8c5493b65
# ╠═32f48399-a3ae-4166-883d-08efab4b0278
# ╟─9ab5b169-8f80-4207-bd42-605a799bcb00
# ╠═6180a47f-eb3a-40f2-b09e-314697001e1c
