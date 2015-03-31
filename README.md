# Cow-Bull-Solver
Solves the "cow bull" number guessing game

##Rules of game
1. I think of a number
2. You guess a number consisting of N unique digits (usually 4).
3. I tell respond "c cows, b bulls" where c is the number of occurences of one of your numbers in my number in the incorrect place and b is the number of occurrences of one of your numbers in the correct position.
4. Repeat steps 2 and 3 until you guess my exact number

* See here: http://en.wikipedia.org/wiki/Bulls_and_cows

#Example
1. I secretly choose the number 7321
2. You guess 1234
3. I respond 3 cows, 0 bulls.
4. You guess 5678, I respond 1 cow, 0 bulls.
5. You guess 7312, I respond, 2 cows 2 bulls.
6. You guess 7321, I respond 4 bulls.
7. You've won in 6 tries.
 
#This program's performance
* There are 5040 possible games. 
* The decision tree this algorithm generates solves every possible answer in an average of 5.78 guesses. The guesses have the following guess counts:
1. 1
2. 2
3. 21
4. 174
5. 1309
6. 2885
7. 648
* For reference, the best known solution solves in an average of 5.2131 turns with no more than 50 7-try games.
* So the good news is we've kept the total number of guesses in every game at 7 or less, which makes this solution more or less optimal.
* The bad news, is we're still half a turn a way from the optimal average guess count, and we have 600 more 7 try games then necessary.
* The other bad news is this code takes a long time to run because it uses an N x N matrix, with approximately 5040^2 cells. It currently takes about 30-60 seconds per game, and to solve for all games 1-2 days on a single machine.
* I am currently working on ways to speed up this code. Once it's faster, I can try tweaking the algorithm to get better scores.
