using Test
using Bonito
using CytoscapeJS

function readme_blocks(path)
    blocks = Tuple{String, String}[]
    section = "intro"
    current = nothing
    for line in eachline(path)
        if current === nothing
            if startswith(line, "#")
                section = strip(lstrip(line, ['#', ' ']))
            elseif startswith(line, "```julia")
                current = String[]
            end
        elseif startswith(line, "```")
            push!(blocks, (section, join(current, "\n")))
            current = nothing
        else
            push!(current, line)
        end
    end
    blocks
end

@testset verbose = true "readme" begin
    path = joinpath(@__DIR__, "..", "README.md")
    blocks = readme_blocks(path)
    @test !isempty(blocks)

    sandbox = mktempdir()
    mod = Module(:READMESandbox)
    Core.eval(mod, :(using Bonito, Observables, CytoscapeJS))
    Core.eval(mod, :(readme_render(x) = (sprint(io -> show(io, MIME"text/html"(), x)); nothing)))

    counts = Dict{String, Int}()
    for (section, block) in blocks
        n = counts[section] = get(counts, section, 0) + 1
        name = n == 1 ? section : "$section ($n)"
        file = joinpath(sandbox, replace(name, r"[^A-Za-z0-9]+" => "_") * ".jl")
        write(file, replace(block, "display(" => "readme_render("))
        @testset "$name" begin
            @test (Base.include(mod, file); true)
        end
    end
end
