if !@isdefined(play)
    include("ui.jl")
end

"""
The default UI for UpSums. A single player untimed version of the game that uses the
command line interface.
"""
struct CLI end
defaultui = CLI()

function start(::CLI)
    println("""

        =================
        WELCOME TO UPSUMS
        =================
        """)
end

function lettersgame_start(::CLI)
    println("""
        =============
        LETTERS ROUND
        =============
        """)
end

function lettersgame_showletters(::CLI, letters)
    println("    ", uppercase(join(letters, " ")))
end

function lettersgame_promptnextletter(::CLI, letters)::LetterType
    print("Vowel or consonant? ")
    while true
        input = lowercase(lstrip(readline()))
        if occursin("please", input) && (isempty(letters) || rand() < 0.3)
            println("Thank you.")
        end
        if isempty(input) || occursin(r"cho(os|ic)e", input)
            return AnyLetter
        elseif input == "c" || occursin("consonant", input)
            return Consonant
        elseif input == "v" || occursin("vowel", input)
            return Vowel
        end
        print("I didn't understand that.\nWould you like a vowel or a consonant? ")
    end
end

function lettersgame_promptanswer(ui::CLI, letters)
    println("\nThe letters are:\n")
    lettersgame_showletters(ui, letters)
    print("\nWhat is your word? ")
    readline()
end

function lettersgame_showlongestwords(::CLI, longwords::Vector{<:AbstractString}, maxlen::Int)
    wordcount = min(length(longwords), 3)
    println("The longest word$(wordcount > 1 ? "s were" : " was") \"$(
            join(longwords, "\", \"", "\" or \"")
        )\" for $(maxlen).")
end

function lettersgame_foundaword(::CLI, word::AbstractString, score::Integer, islongest::Bool)
    println("Well done! You scored $(score) points.")
    if length(word) == 9
        println("That's a bonus 9 points for using all of the letters.")
    elseif islongest
        println("We couldn't find anything longer than that.")
    end
end

function lettersgame_missingletters(::CLI, word::AbstractString, missingletters)
    println(
        "You don't have the right letters for \"",
        uppercase(word),
        "\".\n",
        "You need another '",
        join(missingletters, "', '", "' and '"),
        "' to make that word."
    )
end

function lettersgame_notindictionary(::CLI, word)
    println("I'm afraid \"$(uppercase(word))\" isn't in the dictionary.")
end

function numbersgame_start(::CLI)
    println("""
    =============
    NUMBERS ROUND
    =============
    """)
end

function numbersgame_promptbignumbers(::CLI)::Int
    bigs = -1
    while !(0 <= bigs <= 4)
        print("How many big numbers would you like? ")
        input = readline()
        bigs = something(tryparse(Int, input), -1)
        if isempty(input)
            bigs = rand(0:4)
        end
        if !(0 <= bigs <= 4)
            println("Please pick a number between 0 and 4.")
        end
    end
    bigs
end

function numbersgame_promptanswer(::CLI, target::Integer, numbers::Vector{Int})::Int
    print("""
        The target is $(target).

            $(join(lpad.(numbers, 4)))

        How close did you get? """)

    actual = tryparse(Int, readline())
    while isnothing(actual)
        print("Please enter a number. How close did you get? ")
        actual = tryparse(Int, readline())
    end
    actual
end

function numbersgame_promptattempt(::CLI)::Union{Int,Expr}
    print("How did you do it? ")
    attempt = untrustedtryparse(readline())
    while !(attempt isa Integer || (attempt isa Expr && isvalidsymbols(attempt)))
        println("You may only add, subtract, multiply or divide.")
        print("How did you do it? ")
        attempt = untrustedtryparse(readline())
    end
    attempt
end

function numbersgame_success(::CLI, target, actual, score)
    println(
        iszero(score) ? "" : "Well done! ",
        if actual != target && !iszero(score)
            "You were $(abs(target - actual)) away, that's worth "
        else
            "You scored "
        end,
        iszero(score) ? "no" : score,
        " points.")
end

function numbersgame_failure_badworking(::CLI, actual, expected)
    println("""It seems you've made a mistake there.
        You declared $(expected) but your working gave $(actual).""")
end

function numbersgame_failure_baddivision(::CLI)
    println("You can't divide numbers if they don't divide evenly.")
end

function numbersgame_failure_badsubtraction(::CLI)
    println("Only positive integers are allowed, you can't use 0 or below.")
end

function numbersgame_failure_missingnumbers(::CLI, missingnumbers)
    println(
        "You're missing a few numbers, you need another ",
        join(missingnumbers, ", ", " and "),
        " to do that."
    )
end

function numbersgame_showsolution(::CLI, solution::Expr)
    println("It can be done, you could have ", solution)
end


function nineogram_start(::CLI)
    println("""
        99999999999
        NINE-O-GRAM
        99999999999
        """)
end

function nineogram_promptanswer(::CLI, letters)
    print("""$(uppercase(join(letters, " ")))

    Attempt a word: """)
    readline()
end

function nineogram_success(::CLI, answer::AbstractString, expected::AbstractString)
    print("""
        Let's see if it's up there!

            $(uppercase(expected))

        $(answer == expected ? "" :
            "It's not what we expected, but \"$(uppercase(answer))\" is in the dictionary.\n"
        )Well done! """)
end

function nineogram_failure(::CLI, answer::AbstractString, expected::AbstractString)
    println("T$(isempty(answer) ? "" : "hat's not it, t")he word was \"$(uppercase(expected))\".")
end

function showroundscore(::CLI, score::Integer)
    println(
        "You scored ",
        "$(iszero(score) ? "no" : score) point$(isone(score) ? "" : "s")" ,
        " this round."
    )
end

function showscore(::CLI, scores)
    println(if length(scores) == 1
        "You have $(only(scores)) points."
    else
        "The scores are $(join(scores, " to "))."
    end, '\n')
end

finish(::CLI, _...) = println("Thanks for playing!")
