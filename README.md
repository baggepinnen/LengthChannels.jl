# LengthChannels.jl

[![Build Status](https://travis-ci.org/baggepinnen/LengthChannels.jl.svg?branch=master)](https://travis-ci.org/baggepinnen/LengthChannels.jl)
[![codecov](https://codecov.io/gh/baggepinnen/LengthChannels.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/baggepinnen/LengthChannels.jl)

This package defines a type `LengthChannel{T} <: AbstractChannel{T}` which simply adds information about the length of the channel when it is iterated. The constructor behaves the same as the constructor for `Channel`, but takes an additional integer specifying the length. This length is not to be confused with the buffer size of the channel. When a `LengthChannel` is iterated, it continues until it has iterated the specified number of elements, after that the channel may be automatically closed (keyword `autoclose`), even if there are more elements put in the channel.

Examples:

```julia
using LengthChannels, Test
len,bufsize = 10,4
lc = LengthChannel{Int}(len, bufsize) do ch
    for i = 1:100
        put!(ch, i)
    end
end

@test length(lc) == len
cc = collect(lc)
@test length(cc) == len
@test cc == 1:l
@test isopen(lc)
```

The constructor to a `LengthChannel` takes a keyword argument `autoclose=false (default)` which determines if the channel closes automatically after having iterated for the specified length. It might be useful to keep it open if you want to iterate the specified length several times, e.g. by performing several epochs of training. Just make sure the channel is still being populated, using e.g. the `while true` pattern below.



## Use as buffered iterator for machine learning
A typical use-case for a channel with length is as a buffered dataset for training machine learning models. The following is an example that reads audio data from disk and does some light pre-processing before putting it in the channel
```julia
using LengthChannels, Flux, Random
files      = readdir(path_to_datafiles)
buffersize = 10
dataset = LengthChannel{Vector{Float32}}(length(files), buffersize, spawn=true) do ch
    while true
        for file in shuffle(files)
            data = read_from_disk(file)
            data = pre_process(data)
            put!(ch, data)
        end
    end
end
```
The `while true` pattern is useful when you want to be able to iterate the channel several times over. Each time the channel above is iterated, it will produce `length(files)` values, but it can be iterated again without recreating the channel. If the `while true` loop was omitted, the channel would be closed after one full iteration.

A **batch iterator** suitable for training CNN models in Flux can be obtained like so
```julia
batchsize  = 16
buffersize = 10
files      = readdir(path_to_datafiles)
dataset = LengthChannel{Array{Float32,4}}(length(files)÷batchsize, buffersize, spawn=true) do ch
    batch = Array{Float32,4}(undef,height,width,nchannels,batchsize) # Batches in last dim
    bi = 1 # Batch index
    while true
        for file in shuffle(files)
            data = read_from_disk(file)
            batch[:,:,:,bi] .= data
            bi += 1
            if bi > batchsize
                bi = 1
                put!(ch, copy(batch))
            end
        end
    end
end
```
where `height,width,nchannels` are integers specifying the size of your data.

## Putting data on GPU
You may not put data on the GPU from any other thread than the main thread, hence `spawn=false` is required for a channel putting data on GPU. To still allow reading and preprocessing on a separate thread (this is more performant), we provide the wrapper constructor `LengthChannel{T}(f, dataset::LengthChannel)`, which returns a new `LengthChannel` where `f` is applied to each element of `dataset`.

If `T` is omitted while wrapping a channel, it is assumed that `f(eltype(dataset)) == typeof(f(::eltype(dataset)))` or in words, `f` must have a method returning the type resulting from applying `f` to an element of the wrapped channel.

By having `f=cu` or `f=gpu` which puts data on a GPU, you now have an efficient way of training models on the GPU, while reading data in a separate thread. Primitive benchmarking showed some 0-20% performance improvement using this strategy over putting data on the GPU as it is taken out of the dataset. If `cu/gpu` become thread-safe, this improvement may become larger.

*Note:* If your entire dataset fit onto the GPU and you do not run out of memory while performing backpropagation, the fastest method is *by far* to keep all data on the GPU during the entire training. You can try by simply `gpu.(collect(dataset))` or `collect(dataset)` if the channel already puts data on the GPU. The function `fullsizeof(dataset::LengthChannel)` will tell you the size in bytes required to `collect` the dataset.
