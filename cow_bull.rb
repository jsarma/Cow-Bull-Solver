

class CowBull
	def run
		@n = 100
		@matrix = init_matrix

		while true do
			#get guess with best score
			guess = compute_guess

			#make guess and get response from input
			puts 'Guess:', guess
			puts 'Response?'
			response = readline

			if (response == 40)
				puts 'We did it!'
				return
			end
			#update matrix
			update_matrix(guess, response)
		end
	end

	def init_matrix
		return Array.new(@n) do |row_index|
			Array.new(@n) do |col_index|
				respond(row_index.to_s, col_index.to_s)
			end
		end
	end

	def update_matrix(guess, response)
		#eliminate all answers that this response renders invalid
		@matrix[guess].each_with_index do |col, col_index|
			if (response != col)
				#skip this answer in the future (yes, col_index becomes row index)
				@matrix[col_index] = -1
			end
			# #remove this answer from all future guess calculations
			# matrix.each_with_index do |row, row_index|
			# 	matrix[i][j] = -1
			# end
		end
		#don't try the same guess twice
		@matrix[guess.to_i] = -1
	end

	#use the existing matrix to calculate and return the guess that will eliminate the most possible answers
	#The heuristic we use is to count the total number of possible answers the most likely response would eliminate
	#This requires us figure out the most likely response and remove it from the count.
	def compute_guess
		best_guess_score = 0
		best_guess_index = -1
		@matrix.each_with_index do |row, row_index|
			next if (row == -1)  #skip possibilities we've already eliminated
			x = {}
			score = 0
			row.each_with_index do |col, col_index|
				next if (col == -1) #skip possibilities we've already eliminated
				x[row_index] ||= 0
				x[row_index] += col
				score += 1
			end
			score -= x.max_by{|k,v| v}.first() #heuristic: remove the answers associated with the most likely response from count
			if (score > best_guess_score)
				best_guess_score = score
				best_guess_index = row_index
			end
		end
		return best_guess_index
	end

	# given a guess and an answer, calculate the correct game response.
	# For each digit placed correctly, assign 10 points.
	# For each digit in the number, but not placed correctly, assign 1 point.
	# The correct answer returns 40.
	# This function more or less defines the rules of the game
	def respond(guess, answer)
		response = 0
		guess.split('').each_with_index do |char, char_index|
			if (guess[char_index] == answer[char_index])
				response += 10
			elsif (answer.match(guess[char_index]))
				response += 1
			end
		end
		return response
	end


end


cow_bull = CowBull.new
cow_bull.run
