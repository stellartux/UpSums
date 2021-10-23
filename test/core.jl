include("../src/core.jl")

@testset "Number Solver" begin
    # Can find a number in a list
    @test numbersolver(100, [100, 75, 50, 25, 1, 2]) == 100

    # Can find a number that is the sum of two numbers
    @test numbersolver(101, [100, 1, 3, 5, 7, 9]) == :(100 + 1)

    # Can find a number that is the sum of several numbers
    @test numbersolver(116, [100, 9, 7, 5, 3, 1]) == :(100 + 9 + 7)

    # Can find a number that is the product of two numbers
    @test numbersolver(200, [100, 2, 7, 9, 4, 5]) == :(100 * 2)

    # Can find a number that is a product of several numbers
    @test numbersolver(720, [2:7...]) == :(2 * 3 * 4 * 5 * 6)

    # Can find solutions that require subtraction
    @test numbersolver(99, [100, 25, 1, 1, 1, 1]) == :(100 - 1)

    # Can find solutions that require multiple subtractions or addition before subtraction
    @test numbersolver(122, [100, 25, 2, 1]) == :(100 + (25 - (2 + 1)))

    # Can find solutions that require addition before multiplication
    @test numbersolver(66, [8, 4, 3, 2]) == :((8 + 3) * (2 + 4))
end
