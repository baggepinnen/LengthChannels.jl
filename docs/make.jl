using LengthChannels
using Documenter

makedocs(;
    modules=[LengthChannels],
    authors="Fredrik Bagge Carlson <baggepinnen@gmail.com>",
    repo="https://github.com/baggepinnen/LengthChannels.jl/blob/{commit}{path}#L{line}",
    sitename="LengthChannels.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://baggepinnen.github.io/LengthChannels.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/baggepinnen/LengthChannels.jl",
)
