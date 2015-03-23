

class CowBull

	def debug(msg)
		#puts msg
	end 

	def run
		@num_digits = 3

		@n = (10 ** @num_digits) #max possible guess. min is always 0
		debug "N: #{@n}"
		@matrix = init_matrix
		print_matrix

		while true do
			#get guess with best score
			guess = compute_guess
			debug 'Failed to solve' if guess == -1

			#make guess and get response from input
			puts 'Guess:', stringify_index(guess)
			puts 'Response?'
			response = readline.chomp.to_i

			if (response == @num_digits * 10)
				puts 'We did it!'
				return
			end
			#update matrix
			update_matrix(guess, response)
			print_matrix
		end
	end

	def init_matrix
		#initialize with responses
		return Array.new(@n) do |row_index| #guesses
			if (!is_legal_answer(row_index))
				-1
			else
				Array.new(@n) do |col_index| #possible correct answers
					if (!is_legal_answer(col_index))
						-1
					else
						#response if the col_index word the correct answer and the row_index were the guess				
						respond(row_index.to_s, col_index.to_s)
					end
				end
			end
		end		
	end

	def print_matrix #debug
		# debug @matrix.inspect
		@matrix.each_with_index do |row, row_index|
			next if (row==-1)
			row.each_with_index do |col, col_index|
				next if (col==-1)
				debug "(#{stringify_index(row_index)}, #{stringify_index(col_index)}): #{col}"
			end
		end

	end


	def update_matrix(guess, response)
		debug "UPDATE_MATRIX: #{guess}, #{response}"
		#eliminate all answers that this response renders invalid
		@matrix[guess].each_with_index do |col, col_index|
			next if (col == -1)
			debug "#{col_index}: #{col}"
			if (response != col)
				#skip this answer in the future (yes, col_index becomes row index)
				@matrix[col_index] = -1
				debug "MARKING #{col_index}"
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
			debug "SCORES: #{x}"
			score -= x.max_by{|k,v| v}.first() if (x.size>1) #heuristic: remove the answers associated with the most likely response from count
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
		str_guess = stringify_index(guess)
		str_answer = stringify_index(answer)
		str_guess.split('').each_with_index do |char, char_index|
			if (str_guess[char_index] == str_answer[char_index])
				response += 10
			elsif (str_answer.match(str_guess[char_index]))
				response += 1
			end
		end
		return response
	end

	def is_legal_answer(x) #answer is not legal if there's a repeated digit
		h = {}
		# debug "LEGAL? #{x}"
		stringify_index(x).split('').each do |char|
			# print "#{char} "
			return false if (h[char]) #found repeat!
			h[char] = true
		end
		# debug "LEGAL!"
		return true
	end

	def stringify_index(x)
		x.to_s.rjust(@num_digits,'0')
	end

end


cow_bull = CowBull.new
cow_bull.run
