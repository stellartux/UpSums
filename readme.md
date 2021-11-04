# UpSums

[![Docs](https://img.shields.io/badge/docs-stable-blue.svg)](https://stellartux.github.io/UpSums/)
[![License](https://img.shields.io/github/license/stellartux/UpSums)](./blob/master/LICENSE)

The game with the letters and the numbers and the big blue clock. 🟦🕛🟦

## To Play

Install [Julia](https://julialang.org/) then run the following code.

```julia
using Pkg
Pkg.add(url="https://github.com/stellartux/UpSums/")
using UpSums
play()
```

## Sample Usage

```console
julia> UpSums.play()

=================   
WELCOME TO UPSUMS   
=================   

=============       
LETTERS ROUND       
=============       

Vowel or consonant? A consonant please. 
Thank you.
    S
Vowel or consonant? And a vowel.
    S U
Vowel or consonant? Another vowel.
    S U A
Vowel or consonant? Consonant.
    S U A B
Vowel or consonant? Consonant.
    S U A B C       
Vowel or consonant? Vowel.
    S U A B C U     
Vowel or consonant? Vowel.
    S U A B C U O   
Vowel or consonant? Consonant.
    S U A B C U O B 
Vowel or consonant? And a final... consonant please.
    S U A B C U O B C

The letters are:     

    S U A B C U O B C

What is your word? cabs
Well done! You scored 4 points.      
The longest word was "SUCCUBA" for 7.
You scored 4 points this round.      
You have 4 points.

=============
LETTERS ROUND
=============

Vowel or consonant? c
    P
Vowel or consonant? c
    P T
Vowel or consonant? c
    P T T
Vowel or consonant? c
    P T T R
Vowel or consonant? c
    P T T R P       
Vowel or consonant? v
    P T T R P O
Vowel or consonant? v
    P T T R P O O
Vowel or consonant? v
    P T T R P O O I
Vowel or consonant? v
    P T T R P O O I O

The letters are:

    P T T R P O O I O

What is your word? troop
Well done! You scored 5 points.
The longest words were "TIPTOP", "TROPPO" or "ROOPIT" for 6.
You scored 5 points this round.
You have 9 points.

=============
NUMBERS ROUND
=============

How many big numbers would you like? 2
The target is 264.

      75 100  10   8   2   4

How close did you get? 264
How did you do it? 2 * (100 + 8 * 4)
Well done! You scored 10 points.
You scored 10 points this round.
You have 19 points.

=============
LETTERS ROUND
=============

Vowel or consonant? c
    C
Vowel or consonant? c
    C T
Vowel or consonant? c
    C T T
Vowel or consonant? c
    C T T R
Vowel or consonant? c
    C T T R R
Vowel or consonant? c
    C T T R R W

The letters are:

    C T T R R W I A I

What is your word? tract
Well done! You scored 5 points.
The longest word was "TRIATIC" for 7.
You scored 5 points this round.
You have 24 points.

=============
LETTERS ROUND
=============

Vowel or consonant? v
    O
Vowel or consonant? v
    O E
Vowel or consonant? v
    O E E
Vowel or consonant? v
    O E E O
Vowel or consonant? v
    O E E O A

The letters are:

    O E E O A P C R R

What is your word? career
Well done! You scored 6 points.
The longest words were "CAPERER", "PRERACE" or "CORPORA" for 7.
You scored 6 points this round.
You have 30 points.

=============
NUMBERS ROUND
=============

How many big numbers would you like? 2
The target is 193.

      50 100  10   5   6   1

How close did you get? 195
How did you do it? (50 - 1) * (10 - 6)   
It seems you've made a mistake there.
You declared 195 but your working gave 196.
You scored no points this round.
You have 30 points.

=============
LETTERS ROUND
=============

Vowel or consonant?
    B Z I O A N R
Vowel or consonant?
    B Z I O A N R O
Vowel or consonant?
    B Z I O A N R O M

The letters are:

    B Z I O A N R O M

What is your word? brain
Well done! You scored 5 points.
The longest words were "AMORINO", "BORAZON" or "BORONIA" for 7.
You scored 5 points this round.
You have 35 points.

=============
LETTERS ROUND
=============

Vowel or consonant?
    E A N H O N Z
Vowel or consonant?
    E A N H O N Z U
Vowel or consonant?
    E A N H O N Z U G

The letters are:

    E A N H O N Z U G

What is your word? unzone
I'm afraid "UNZONE" isn't in the dictionary.
The longest words were "UNHANG", "GUENON" or "NONAGE" for 6.
You scored no points this round.
You have 35 points.

=============
NUMBERS ROUND
=============

How many big numbers would you like? 2
The target is 974.

      25  75   2   5   7   8

How close did you get? 975
How did you do it? 75 * (5 + 8)
Well done! You were 1 away, that's worth 7 points.
You scored 7 points this round.
You have 42 points.

=============
LETTERS ROUND
=============

Vowel or consonant?
    N O L E R S E
Vowel or consonant?
    N O L E R S E E
Vowel or consonant?
    N O L E R S E E D

The letters are:

    N O L E R S E E D

What is your word? lenders
Well done! You scored 7 points.
The longest words were "NEEDLERS" or "ENDORSEE" for 8.
You scored 7 points this round.
You have 49 points.

=============
LETTERS ROUND
=============

Vowel or consonant?
    D L A F I E P
Vowel or consonant?
    D L A F I E P E
Vowel or consonant?
    D L A F I E P E B

The letters are:

    D L A F I E P E B

What is your word? afield
Well done! You scored 6 points.
The longest word was "DEFIABLE" for 8.
You scored 6 points this round.
You have 55 points.

=============
LETTERS ROUND
=============

Vowel or consonant?
    N N E I E N R
Vowel or consonant?
    N N E I E N R T
Vowel or consonant?
    N N E I E N R T A

The letters are:

    N N E I E N R T A

What is your word? entrain
Well done! You scored 7 points.
We couldn't find anything longer than that.
You scored 7 points this round.
You have 62 points.

=============
LETTERS ROUND
=============

Vowel or consonant?
    U A D N E G R
Vowel or consonant?
    U A D N E G R U
Vowel or consonant?
    U A D N E G R U S

The letters are:

    U A D N E G R U S

What is your word? ganders
Well done! You scored 7 points.
The longest words were "UNGUARDS" or "UNARGUED" for 8.
You scored 7 points this round.
You have 69 points.

=============
NUMBERS ROUND
=============

How many big numbers would you like?
The target is 715.

      75 100  25   3   3   2

How close did you get? 710
How did you do it? (100 + 25 - 3) * (3 + 2)
It seems you've made a mistake there.
You declared 710 but your working gave 610.
It can be done, you could have 75 + (2 + 3) * (100 + 25 + 3)
You scored no points this round.
You have 69 points.

99999999999
NINE-O-GRAM
99999999999

I R E S A O R H H

Attempt a word: horishare
That's not it, the word was "HORSEHAIR".
You have 69 points.

Thanks for playing!
```

## Potential Future Features

- Standalone executable
- TUI
- Native GUI
- Web based GUI
- P2P multiplayer
- ~~Open world and crafting system~~
