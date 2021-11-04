if !@isdefined(wordlist)
    include("core.jl")
end

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
function play(ui = defaultui; format::Symbol = :full)
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

@enum LetterType AnyLetter Vowel Consonant

function lettersgame(ui)
    letters = Char[]
    vowels = 1
    consonants = 1
    index = 1
    lettersgame_start(ui)
    while index <= 9 && vowels > index - 6 && consonants > index - 5
        lettertype = lettersgame_promptnextletter(ui, letters)
        if lettertype == AnyLetter
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
            lettersgame_showletters(ui, letters)
        elseif lettertype == Consonant
            consonants += 1
            push!(letters, randconsonant())
            lettersgame_showletters(ui, letters)
        elseif lettertype == Vowel
            vowels += 1
            push!(letters, randvowel())
            lettersgame_showletters(ui, letters)
        end
        index = length(letters) + 1
    end
    for _ in consonants:4
        push!(letters, randconsonant())
    end
    for _ in vowels:3
        push!(letters, randvowel())
    end

    word = lowercase(strip(lettersgame_promptanswer(ui, letters)))
    longwords, maxlen = longest(letters)

    indictionary = haskey(wordlist, word)
    usesletters = issubcol(collect(word), letters)
    foundaword = indictionary && usesletters && !isempty(word)
    len = length(word)
    score = (foundaword + (len == 9)) * len

    if foundaword
        lettersgame_foundaword(ui, word, score, len == maxlen)
    end
    if !usesletters && indictionary
        lettersgame_missingletters(ui, word, uppercase.(missingvalues(collect(word), letters)))
    end
    if !isempty(word) && !indictionary
        lettersgame_notindictionary(ui, word)
    end
    if !(foundaword && len == maxlen)
        wordsfound = min(3, length(longwords))
        lettersgame_showlongestwords(ui, uppercase.(shuffle!(longwords)[1:wordsfound]), maxlen)
    end

    showroundscore(ui, score)

    score
end

function numbersgame(ui)
    numbersgame_start(ui)

    bigs = numbersgame_promptbignumbers(ui)
    target, numbers = randnumbers(bigs)

    actual = numbersgame_promptanswer(ui, target, numbers)

    attemptinrange = abs(actual - target) <= 10
    attempt = attemptinrange ? numbersgame_promptattempt(ui) : actual
    attemptisvalid = isvalidattempt(actual, numbers, attempt)

    if attemptinrange && attemptisvalid
        score = numberscore(target, actual)
        numbersgame_success(ui, target, actual, score)
        showroundscore(ui, score)
        score
    else
        if attemptinrange
            result = Int(floor(eval(attempt)))
            if actual != result
                numbersgame_failure_badworking(ui, result, actual)
            end
            if !isvaliddivision(attempt)
                numbersgame_failure_baddivision(ui)
            end
            if !isvalidsubtraction(attempt)
                numbersgame_failure_badsubtraction(ui)
            end
            if !isvalidnumbers(attempt, numbers)
                numbersgame_failure_missingnumbers(ui, missingvalues(keep(Int, attempt), numbers))
            end
        end
        solution = numbersolver(target, numbers)
        if !isnothing(solution)
            numbersgame_showsolution(ui, solution)
        end
        showroundscore(ui, 0)
        0
    end
end

function nineogram(ui)
    expected = rand(nineograms)
    letters = shuffle!([expected...])

    nineogram_start(ui)
    answer = lowercase(strip(nineogram_promptanswer(ui, letters)))

    if !isempty(answer) && haskey(wordlist, answer)
        nineogram_success(ui, answer, expected)
        10
    else
        nineogram_failure(ui, answer, expected)
        0
    end
end

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
