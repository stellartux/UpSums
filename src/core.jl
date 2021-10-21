using DataStructures, Base.Iterators, Random

"Counts each element in `iter`. Returns a dictionary of values to counts."
function elcount(iter)
    dict = Dict{eltype(iter),Int}()
    for val in iter
        dict[val] = get(dict, val, 0) + 1
    end
    dict
end

struct Sampler{V,R<:Real}
    values::Vector{Pair{R,V}}
end

function Sampler(counts::Dict{V,R}) where {V, R<:Real}
    values = Pair{R,V}[]
    total = zero(R)
    for (key, value) in pairs(counts)
        total += value
        push!(values, total => key)
    end
    Sampler(values)
end

function Base.rand(sampler::Sampler)
    sampler.values[
        searchsortedfirst(sampler.values, first(last(sampler.values)) * rand(), by=first)
    ][2]
end
(sampler::Sampler)() = rand(sampler)

loadwordlist(path::AbstractString) = Trie{Int}(line => length(line) for line in eachline(path))
wordlist = loadwordlist(joinpath(@__DIR__, "../data/dictionary-en_GB.txt"));
nineograms = Set(eachline("data/nineograms-en_GB.txt"))

randvowel, randconsonant = begin
    consonantcounts = elcount(c for c in read("data/dictionary-en_GB.txt", String) if isletter(c))
    vowelcounts = empty(consonantcounts)
    for vowel in "aeiou"
        if haskey(consonantcounts, vowel)
            vowelcounts[vowel] = consonantcounts[vowel]
            delete!(consonantcounts, vowel)
        end
    end
    Sampler(vowelcounts), Sampler(consonantcounts)
end

randletter() = rand((randvowel, randconsonant))()
randletters() = shuffle!([f() for f in (randvowel, randconsonant, randletter) for _ in 1:3])

allwords(letters) = allwords(wordlist, letters)
allwords(letters::AbstractString) = allwords(wordlist, [letters...])
allwords(::Nothing, _...) = []

function allwords(trie, letters, prefix = "")
    words = String[]
    for n in 1:length(letters)
        ls = circshift(letters, n)
        c = string(popfirst!(ls))
        if haskey(trie, c)
            push!(words, prefix * c)
        end
        s = subtrie(trie, c)
        if !isempty(ls) && !isnothing(s)
            append!(words, allwords(s, ls, prefix * c))
        end
    end
    sort!(words, by = length, rev = true)
    unique!(words)
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

function issubcol(subcol, supercol)
    subcount = elcount(subcol)
    supercount = elcount(supercol)
    all(haskey(supercount, key) && supercount[key] >= value for (key, value) in pairs(subcount))
end

"""

    validate(target::Integer, numbers, attempt::AbstractString)

Validates that the given `attempt` at calcuting `target` using the given `numbers` and
the operations `+`, `-`, `*` and `/`.
"""
function validate(target::Integer, numbers, attempt::AbstractString)
    if !(
        # check only uses numbers, arithmetic operations and whitespace
        occursin(r"^([-+*/()]|\d+|\s+)+$", attempt) &&
        # check that only numbers from the allowed collection were used
        issubcol((parse(Int, m.match) for m in eachmatch(r"\d+", attempt)), numbers)
    )
        return false
    end
    parsetree = Meta.parse(attempt)
    # check that the expression evaluates to the correct result
    # and that only well-formed division occurs and no negative numbers occur
    (eval(parsetree) == target) && validate(parsetree)
end

"""

    validate(expr::Expr)

Validates that the given expression does not break the rules of calculation, i.e.
no negative numbers are used and division is only performed if the result is an integer.
"""
function validate(expr::Expr)
    if expr.head == :call
        op = expr.args[1]
        if op == :/ && !iszero(eval(expr.args[2]) % eval(expr.args[3])) ||
                op == :- && eval(expr) < 0 ||
                !validate(op)
            return false
        end
    end
    all(validate, expr.args)
end
validate(n::Integer) = n > 0
validate(s::Symbol) = s in Set((:+, :-, :*, :/, :call))

"""

    randnumbers(bigs::Integer) -> (target, numbers)

Generates a target and six numbers for a round of the numbers game.
"""
function randnumbers(bigs::Integer)
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
The default UI for UpSums. A single player untimed version of the game that uses the
command line interface.
"""
struct CLI end

"""

    play(ui = CLI())

Play a round of UpSums with the given number of players.

The `ui` object must implement the following interface.

- `lettersgame(ui)`
- `numbersgame(ui)`
- `nineogram(ui)`

The following functions are optional but may be useful for displaying information and
managing state.

- `start(ui)` Called at the beginning of a new game.
- `showscore(ui, scores)`
- `winner(ui, winners, scores)`
- `finish(ui)` Called when the game is over.

"""
function play(ui = CLI())
    format = (
        lettersgame,
        lettersgame,
        numbersgame,
        # tea-time teaser
        lettersgame,
        lettersgame,
        numbersgame,
        lettersgame,
        lettersgame,
        numbersgame,
        # tea-time teaser
        lettersgame,
        lettersgame,
        lettersgame,
        lettersgame,
        numbersgame,
        nineogram
    )

    try
        while true
            start(ui)
            scores = zeros(Int)
            for round in format
                scores .+= round(ui)
                showscore(ui, scores)
            end
            winner(ui, scores, findall(==(maximum(scores)), scores))
            if !playagain(ui)
                break
            end
        end
    catch err
        if !(err isa InterruptException)
            rethrow(err)
        end
    finally
        finish(ui)
    end
end

"""

    start(ui)

Start a game of UpSums.
"""
start(_...) = nothing

"""

    showscore(ui, scores)

Display the current score to the user.
"""
showscore(_...) = nothing

"""

    winner(ui, winners, scores)

Display the winner of the game on the UI.
"""
winner(_...) = nothing

"""

    playagain(ui)

Called to determine if the player wants to play another round.
"""
playagain(_...) = false

"""

    finish(ui)

Wrap up a game of UpSums.
"""
finish(_...) = nothing

function start(::CLI)
    println("""

        =================
        WELCOME TO UPSUMS
        =================
        """)
end

function lettersgame(::CLI, _...)
    println("""

        =============
        LETTERS ROUND
        =============
        """)

    letters = Char[]
    showletters() = println("    ", uppercase(join(letters, " ")))
    vowels = 0
    consonants = 0
    while length(letters) < 9 && vowels > length(letters) - 6 && consonants > length(letters) - 5
        print("Vowel or consonant? ")
        str = lowercase(lstrip(readline()))
        if occursin("please", str) && rand() < 0.37
            println("Thank you.")
        end
        if !isempty(str)
            if str == "c" || occursin("consonant", str)
                consonants += 1
                push!(letters, randconsonant())
                showletters()
            elseif str == "v" || occursin("vowel", str)
                vowels += 1
                push!(letters, randvowel())
                showletters()
            end
        end
    end
    for _ in consonants:3
        push!(letters, randconsonant())
    end
    for _ in vowels:2
        push!(letters, randvowel())
    end

    println("\nThe letters are:\n")
    showletters()
    print("\nWhat is your word? ")

    word = lowercase(strip(readline()))
    longwords, maxlen = longest(letters)

    function showlongwords()
        wordsfound = min(length(longwords), 3)
        println("The longest word$(wordsfound > 1 ? "s were" : " was") \"$(
            join(uppercase.(shuffle!(longwords)[1:wordsfound]), "\", \"", "\" or \"")
        )\" for $(maxlen).")
    end

    isindictionary = haskey(wordlist, word)
    usesletters = issubcol(collect(word), letters)
    foundaword = isindictionary && usesletters
    len = length(word)
    score = (foundaword + (len == 9)) * len

    if foundaword
        println("Well done! You scored $(score) points.")
        if len == 9
            println("That's a bonus 9 points for using all of the letters.")
        elseif len == maxlen
            println("We couldn't find anything longer than that.")
        end
    elseif isindictionary
        println("You don't have the right letters for \"", uppercase(word), "\".")
    elseif !isempty(word)
        println("I'm afraid \"$(uppercase(word))\" isn't in the dictionary.")
    end

    if !(foundaword && len == maxlen)
        showlongwords()
    end

    score
end

function numbersgame(::CLI, _...)
    print("""

        =============
        NUMBERS ROUND
        =============

        """)
    bigs = -1
    while !(0 <= bigs <= 4)
        print("How many big numbers would you like? ")
        bigs = something(tryparse(Int, readline()), -1)
        if bigs < 0
            println("Please pick a number between 0 and 4.")
        end
    end
    target, numbers = randnumbers(bigs)
    print("""
        The target is $(target).

            $(join(lpad.(numbers, 4)))

        How close did you get? """)
    actual = tryparse(Int, readline())
    while isnothing(actual)
        print("Please enter a number. How close did you get? ")
        actual = tryparse(Int, readline())
    end
    print("How did you do it? ")
    attempt = readline()
    if validate(actual, numbers, attempt)
        score = numberscore(target, actual)
        println(
            "Well done! ",
            if actual != target
                "You were $(abs(target - actual)) away, that's worth "
            else
                "You scored "
            end,
            score,
            " points.")
        score
    else
        result = eval(Meta.parse(attempt))
        if actual != result
            println("""It seems you've made a mistake there.
            You declared $(actual) but your working gave $(result).""")
        end
        println("You scored no points this round.")
        0
    end
end

function nineogram(::CLI, _...)
    expected = rand(nineograms)
    letters = shuffle!([expected...])

    print("""

        ===========
        NINE-O-GRAM
        ===========

          $(uppercase(join(letters, " ")))

        Attempt a word: """)

    answer = lowercase(strip(readline()))

    if haskey(wordlist, answer)
        print("""
            Let's see if it's up there!

                $(uppercase(expected))

            $(answer == expected ? "" :
                "It's not what we expected, but \"$(uppercase(answer))\" is in the dictionary.\n"
            )Well done! You score 10 points.
            """)
        10
    else
        println("T$(isempty(answer) ? "" : "hat's not it, t")he word was \"$(uppercase(expected))\".")
        0
    end
end

function showscore(::CLI, scores)
    println(if length(scores) == 1
        "You have $(only(scores)) points."
    else
        "The scores are $(join(scores, " to "))."
    end)
end

finish(::CLI, _...) = println("Thanks for playing!")
