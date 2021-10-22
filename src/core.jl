using DataStructures, Base.Iterators, Random, StatsBase

wraploader(str) = isinteractive() ? str : joinpath(@__DIR__, "..", str)
loadwordlist(path::AbstractString) = Trie{Int}(line => length(line) for line in eachline(path))
nineograms = Set(eachline(wraploader("data/nineograms-en_GB.txt")))

wordlist, randvowel, randconsonant = let
    dictionary = read(wraploader("data/dictionary-en_GB.txt"), String)
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
        Trie{Int}(line => length(line) for line in split(dictionary, '\n')),
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

"""
The default UI for UpSums. A single player untimed version of the game that uses the
command line interface.
"""
struct CLI end

"""

    play(ui = CLI(); format = :full)

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

`format` should be one of `:full`, `:nine`, `:three`, `:letters`, `:numbers` or
`:nineogram`.
"""
function play(ui = CLI(); format::Symbol=:full)
    formats = (
        full = (
            lettersgame, lettersgame, numbersgame,
            lettersgame, lettersgame, numbersgame,
            lettersgame, lettersgame, numbersgame,
            lettersgame, lettersgame, lettersgame, lettersgame, numbersgame, nineogram
        ),
        nine = (
            lettersgame, lettersgame, lettersgame, numbersgame,
            lettersgame, lettersgame, lettersgame, numbersgame, nineogram
        ),
        three = (lettersgame, numbersgame, nineogram),
        letters = repeated(lettersgame),
        numbers = repeated(numbersgame),
        nineogram = repeated(nineogram)
    )
    rounds = formats[format]

    try
        while true
            start(ui)
            scores = zeros(Int)
            for round in rounds
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
    showletters(letters) = println("    ", uppercase(join(letters, " ")))
    vowels = 1
    consonants = 1
    index = 1
    while index <= 9 && vowels > index - 6 && consonants > index - 5
        print("Vowel or consonant? ")
        str = lowercase(lstrip(readline()))
        if occursin("please", str) && (index == 1 || rand() < 0.3)
            println("Thank you.")
        end

        if isempty(str) || occursin(r"cho(os|ic)e", str)
            if index == 1
                shuffle!(push!(letters,
                    randconsonant(), randvowel(), randconsonant(), randvowel(),
                    randconsonant(), randvowel(), randconsonant()
                ))
                consonants += 4
                vowels += 3
            else
                push!(letters,
                    if rand(Bool)
                        vowels += 1
                        randvowel()
                    else
                        consonants += 1
                        randconsonant()
                    end
                )
            end
            showletters(letters)
        elseif str == "c" || occursin("consonant", str)
            consonants += 1
            push!(letters, randconsonant())
            showletters(letters)
        elseif str == "v" || occursin("vowel", str)
            vowels += 1
            push!(letters, randvowel())
            showletters(letters)
        end
        index = length(letters) + 1
    end
    for _ in consonants:4
        push!(letters, randconsonant())
    end
    for _ in vowels:3
        push!(letters, randvowel())
    end

    println("\nThe letters are:\n")
    showletters(letters)
    print("\nWhat is your word? ")

    word = lowercase(strip(readline()))
    longwords, maxlen = longest(letters)

    function showlongwords()
        wordsfound = min(length(longwords), 3)
        println("The longest word$(wordsfound > 1 ? "s were" : " was") \"$(
            join(uppercase.(shuffle!(longwords)[1:wordsfound]), "\", \"", "\" or \"")
        )\" for $(maxlen).")
    end

    indictionary = haskey(wordlist, word)
    usesletters = issubcol(collect(word), letters)
    foundaword = indictionary && usesletters
    len = length(word)
    score = (foundaword + (len == 9)) * len

    if foundaword
        println("Well done! You scored $(score) points.")
        if len == 9
            println("That's a bonus 9 points for using all of the letters.")
        elseif len == maxlen
            println("We couldn't find anything longer than that.")
        end
    end

    if !usesletters && indictionary
        println(
            "You don't have the right letters for \"",
            uppercase(word),
            "\".\n",
            "You need another '",
            join(uppercase.(missingvalues(collect(word), letters)), "', '", "' and '"),
            "' to make that word."
        )
    end

    if !isempty(word) && !indictionary
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
        str = readline()
        bigs = something(tryparse(Int, str), -1)
        if isempty(str)
            bigs = rand(0:4)
        end
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
    issuccessfulattempt = abs(actual - target) <= 10
    if issuccessfulattempt
        print("How did you do it? ")
        attempt = untrustedtryparse(readline())
        while !(attempt isa Integer || (attempt isa Expr && isvalidsymbols(attempt)))
            println("You may only use addition, subtraction, multiplication and division.")
            print("How did you do it? ")
            attempt = untrustedtryparse(readline())
        end
    else
        attempt = actual
    end

    if issuccessfulattempt && isvalidattempt(actual, numbers, attempt)
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
        if issuccessfulattempt
            result = Int(floor(eval(attempt)))
            if actual != result
                println("""It seems you've made a mistake there.
                    You declared $(actual) but your working gave $(result).""")
            end
            if !isvaliddivision(attempt)
                println("You can't divide numbers if they don't divide evenly.")
            end
            if !isvalidsubtraction(attempt)
                println("Only positive integers are allowed, you can't use 0 or below.")
            end
            if !isvalidnumbers(attempt, numbers)
                println("You're missing a few numbers, you need another ",
                    join(missingvalues(keep(Int, attempt), numbers), ", ", " and "),
                    " to do that.")
            end
        end
        answer = numbersolver(target, numbers)
        if !isnothing(answer)
            println("It can be done, you could have ", answer)
        end
        println("You scored no points this round.")
        0
    end
end

function nineogram(::CLI, _...)
    expected = rand(nineograms)
    letters = shuffle!([expected...])

    print("""

        99999999999
        NINE-O-GRAM
        99999999999

          $(uppercase(join(letters, " ")))

        Attempt a word: """)

    answer = lowercase(strip(readline()))

    if !isempty(answer) && haskey(wordlist, answer)
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
