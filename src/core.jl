using DataStructures, Base.Iterators, Random, StatsBase

loadwordlist(path::AbstractString) = Trie{Int}(line => length(line) for line in eachline(path))
nineograms = Set(eachline("data/nineograms-en_GB.txt"))

wordlist, randvowel, randconsonant = let
    dictionary = read("data/dictionary-en_GB.txt", String)
    if isempty(dictionary)
        @error "No dictionary found"
    end
    consonantcounts = countmap(char for char in dictionary if isletter(char))
    vowelcounts = empty(consonantcounts)
    for vowel in "aeiou"
        vowelcounts[vowel] = consonantcounts[vowel]
        delete!(consonantcounts, vowel)
    end
    weightedsampler(counts) = let
        ks = collect(keys(counts))
        ws = fweights(collect(values(counts)))
        () -> sample(ks, ws)
    end
    (
        Trie{Int}(line => length(line) for line in split(dictionary, r"\s+")),
        weightedsampler(vowelcounts),
        weightedsampler(consonantcounts)
    )
end;

eachcircshift(coll) = (circshift(coll, n) for n in 0:length(coll) - 1)

"""

    allwords(letters)

Find all the words in the dictionary that can be formed using the given letters.
"""
allwords(letters) = allwords(wordlist, letters)
allwords(letters::AbstractString) = allwords(wordlist, [letters...])
allwords(::Nothing, _...) = []

function allwords(trie, letters, prefix = "")
    words = String[]
    for ls in eachcircshift(letters)
        c = string(popfirst!(ls))
        if haskey(trie, c)
            push!(words, prefix * c)
        end
        s = subtrie(trie, c)
        if !isempty(ls) && !isnothing(s)
            append!(words, allwords(s, ls, prefix * c))
        end
    end
    unique!(sort!(words, by = length, rev = true))
end

longest(word::String) = longest(allwords(word))
longest(word::Vector{Char}) = longest(join(word))

function longest(words)
    if isempty(words)
        words, 0
    else
        maxlen = maximum(length(word) for word in words)
        filter(w -> length(w) == maxlen, words), maxlen
    end
end

function longest(words::Vector{AbstractString})
    if isempty(words)
        words, 0
    else
        collect(takewhile(word -> length(word) == length(first(words)), words))
    end
end

"""

    issubcol(subcol, supercol)

Determines if a collection could be made out of another collection. Differs from `issubset`
in that if the value appears multiple times in `subcol`, it must appear at least that
many times in `supercol`.
"""
function issubcol(subcol, supercol)
    subcount = countmap(subcol)
    supercount = countmap(supercol)
    all(haskey(supercount, key) && supercount[key] >= value for (key, value) in pairs(subcount))
end

"""

    missingvalues(subcol, supercol)

Returns the values which are missing from `supercol` but present in `subcol`.
"""
function missingvalues(subcol, supercol)
    subcount = countmap(subcol)
    supercount = countmap(supercol)
    values = keytype(subcount)[]
    for (key, count) in pairs(subcount)
        for _ in 1:count - get(supercount, key, 0)
            push!(values, key)
        end
    end
    values
end

function isvalidattempt(target, numbers, attempt::AbstractString)
    isvalidattempt(target, numbers, Meta.parse(attempt))
end

isvalidattempt(target::Integer, numbers, number::Integer) = target == number && number in numbers
isvalidattempt(_...) = false

"""

    isvalidattempt(target::Integer, numbers, expr::Expr)

Validates that the given expression does not break the rules of calculation, i.e.
no negative numbers are used and division is only performed if the result is an integer.
"""
function isvalidattempt(target::Integer, numbers, expr::Expr)
    # check that only numbers from the allowed collection were used
    isvalidnumbers(expr, numbers) &&
        # and only the allowed operations were used
        isvalidsymbols(expr)
        # and that only well-formed division occurs
        isvaliddivision(expr) &&
        # and no negative numbers occur
        isvalidsubtraction(expr) &&
        # and that the expression evaluates to the correct result
        (eval(expr) == target)
end

keep(::Type{T}, expr::Expr) where {T} = append!([], keep.(T, expr.args)...)
keep(::Type{T}, value::T) where {T} = T[value]
keep(::Type{T}, _) where {T} = T[]

isvaliddivision(str::AbstractString) = isvaliddivision(Meta.parse(str))
function isvaliddivision(expr::Expr)
    op = expr.args[1]
    if (op == :/ || op == :÷)
        l, r = eval.(expr.args[2:3])
        if iszero(r) || !iszero(l % r)
            return false
        end
    end
    all(isvaliddivision, expr.args)
end
isvaliddivision(_) = true

isvalidsubtraction(str::AbstractString) = isvalidsubtraction(Meta.parse(str))
function isvalidsubtraction(expr::Expr)
    op = expr.args[1]
    if op == :-
        if eval(expr) <= 0
            return false
        end
    end
    all(isvalidsubtraction, expr.args)
end
isvalidsubtraction(_) = true

isvalidnumbers(expr::Expr, numbers) = issubcol(keep(Int, expr), numbers)
isvalidnumbers(number::Integer, numbers) = number in numbers

isvalidsymbols(expr::Expr, symbols = Set((:+, :-, :*, :/, :÷))) =
        issubset(keep(Symbol, expr), symbols)
isvalidsymbols(_...) = false

"Like `Meta.tryparse` but for arithmetic expressions only."
function untrustedtryparse(str::AbstractString)::Union{Expr,Integer,Nothing}
    try
        if occursin(r"^(\s+|\d+|[-+\/*÷()])+$", str)
            return Meta.parse(str)
        end
    catch err
        if !(err isa Meta.ParseError)
            rethrow(err)
        end
    end
    nothing
end

"""

    randnumbers(bigs::Integer) -> (target, numbers)

Generates a target and six numbers for a round of the numbers game.
"""
function randnumbers(bigs::Integer = rand(0:4))
    if bigs < 0 || bigs > 4
        throw(ArgumentError("The player must choose between 0 and 4 large numbers."))
    end
    bignumbers = [25, 50, 75, 100]
    smallnumbers = [1:10..., 1:10...]
    takesome(xs, n) = view(shuffle!(xs), 1:n)
    rand(101:999), [takesome(bignumbers, bigs); takesome(smallnumbers, 6 - bigs)]
end

function numberscore(target::Integer, attempt::Integer)
    diff = abs(target - attempt)
    if diff == 0
        10
    elseif diff <= 5
        7
    elseif diff <= 10
        5
    else
        0
    end
end

function numberscore(target, attempts...)
    diffs = abs.(target .- attempts)
    numberscore.(target, attempts) .* (diffs .== minimum(diffs))
end

"""

    numbersolver(target::Integer, numbers)

Given a target and a list of numbers, tries to find a way of creating the target using
only the numbers provided and addition, subtraction, multiplication and integer division.
"""
function numbersolver(target::Integer, numbers)
    if target <= 0
        return nothing
    end
    if target in numbers
        return target
    end
    for xs in eachcircshift(numbers)
        x = popfirst!(xs)
        if target > x
            if !isone(x) && iszero(target % x)
                expr = numbersolver(target ÷ x, xs)
                if expr isa Expr && first(expr.args) == :*
                    insert!(expr.args, 2, x)
                    return expr
                elseif !isnothing(expr)
                    return Expr(:call, :*, x, expr)
                end
            end
            for ys in eachcircshift(xs)
                y = popfirst!(ys)
                if x + y == target
                    return :($x + $y)
                end
                if iszero(target % (x + y))
                    expr = numbersolver(target ÷ (x + y), ys)
                    if isnothing(expr)
                        continue
                    end
                    lhs = Expr(:call, :+, x, y)
                    if expr isa Expr && first(expr.args) == :*
                        insert!(expr.args, 2, lhs)
                        return expr
                    else
                        return Expr(:call, :*, lhs, expr)
                    end
                end
            end
        else # if target < x
            if iszero(x % target)
                expr = numbersolver(target * x, xs)
                if !isnothing(expr)
                    result = Expr(:call, :/, x, expr)
                    if isvaliddivision(result)
                        return result
                    end
                end
            end
            y = x - target
            expr = numbersolver(y, xs)
            if !isnothing(expr)
                result = Expr(:call, :-, x, expr)
                if isvalidsubtraction(result)
                    return result
                end
            end
        end
        y = target - x
        expr = numbersolver(y, xs)
        if expr isa Expr && first(expr.args) == :+
            insert!(expr.args, 2, x)
            return expr
        elseif !isnothing(expr)
            return Expr(:call, :+, x, expr)
        end
    end
    nothing
end
