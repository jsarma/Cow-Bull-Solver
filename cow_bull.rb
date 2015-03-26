

class CowBull
	@@level = 0

	def debug(msg, level=1)
		puts msg if (level <= @@level)
	end 

	def setup
		@num_digits = 4
		@done_state = @num_digits * 10;
		@n = (10 ** @num_digits) #max possible guess. min is always 0		
		debug "N: #{@n}"
		filename = "cow_bull_#{@num_digits}.matrix";
		if (File.exists?(filename))
			puts "matrix"
			@src_matrix = Marshal.load(File.binread(filename))
		else
			puts "not matrix"
			@src_matrix = init_matrix
			File.open(filename, 'wb') {|f| f.write(Marshal.dump(@src_matrix))}
		end
	end

	def play_with_myself
		game_scores = []
		game_score_sequences = {}
		setup
		ser_matrix = Marshal.dump(@src_matrix)
		#play once for each possible correct answer
		(0..@n).each do |secret|
			next if (!is_legal_answer(secret))
			@matrix = Marshal.load(ser_matrix)
			puts "SECRET: #{secret}"
			guess_count = 1
			while true do
				#get guess with best score
				guess = compute_guess
				if guess == -1
					puts 'Failed to solve... You must be a cheater.'
					return
				end
				#make guess and get response from input
				#puts "Guess ##{guess_count}: #{stringify_index(guess)}"
				response = respond(guess, secret)				
				#puts "Response? #{response}"
				game_score_sequences[secret] ||= []
				game_score_sequences[secret].push(guess)

				if (response == @done_state)
					puts "Solved #{secret} with guess count: #{guess_count} Sequence: #{game_score_sequences[secret]}"
					game_scores.push([secret, guess_count])					
					break
				end
				#update matrix
				update_matrix(guess, response)
				#print_matrix
				guess_count += 1
			end
		end

		score_algorithm(game_scores, game_score_sequences)
	end

	def score_algorithm(game_scores, game_score_sequences)
		puts "Guess Sequences: #{game_score_sequences}"
		puts "Scores: #{game_scores}"
		puts "Max Guesses: #{game_scores.max_by {|k,v| v} }"
		puts "Avg Guesses: #{game_scores.inject(0.0) { |sum, el| sum + el[1] } / game_scores.size }"
	end	

	def play
		setup
		#print_matrix
		@matrix = @src_matrix

		guess_count = 1
		while true do
			#get guess with best score
			guess = compute_guess
			if guess == -1
				puts 'Failed to solve... You must be a cheater.'
				return
			end
			#make guess and get response from input
			puts "Guess ##{guess_count}:", stringify_index(guess)
			puts 'Response?'
			response = readline.chomp.to_i

			if (response == @done_state)
				puts 'We did it!'
				return
			end
			#update matrix
			update_matrix(guess, response)
			#print_matrix
			guess_count += 1
		end
	end

	def init_matrix
		stime = Time.now
		debug 'init matrix', 0
		#initialize with responses
		retval = Array.new(@n) do |row_index| #guesses
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
		debug "init matrix done #{Time.now - stime}", 0
		return retval
	end

	def print_matrix #debug
		# debug @matrix.inspect
		@matrix.each_with_index do |row, row_index|
			next if (row==-1)
			row.each_with_index do |col, col_index|
				#next if (col==-1)
				debug "(#{stringify_index(row_index)}, #{stringify_index(col_index)}): #{col}", 1
			end
		end

	end


	def update_matrix(guess, response)
		debug "UPDATE_MATRIX: #{guess}, #{response}"
		#eliminate all answers that this response renders invalid
		@matrix[guess].each_with_index do |col, col_index|
			next if (col == -1)
			#debug "#{col_index}: #{col}"
			if (response != col)
				# #skip this answer in the future (yes, col_index becomes row index)
				# @matrix[col_index] = -1
				debug "MARKING (#{guess}, #{col_index})", 2

				#remove this answer from all future guess calculations
				@matrix.each_with_index do |row, row_index|
					next if (@matrix[row_index] == -1)
					@matrix[row_index][col_index] = -1
				end

			end
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
				x[col] ||= 0
				x[col] += 1
				score += 1
			end
			prescore = score
			if (x.size==1)
				if (x[@done_state])
					debug "by Jove I think you've got it"
					return row_index
				else
					score = 0;
				end
			else
				score -= x.max_by{|k,v| v}[1] #heuristic: remove the answers associated with the most likely response from count
			end
			debug "SCORES #{row_index}: #{x} #{prescore} #{score}", 1
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
		str_guess = stringify_index guess
		str_answer = stringify_index answer
		str_guess.each_char.with_index do |char, char_index|
			if (str_guess[char_index] == str_answer[char_index])
				response += 10
			elsif (str_answer.match(str_guess[char_index]))
				response += 1
			end
		end
		return response
	end

	@@is_legal_answer = {}
	def is_legal_answer(x) #answer is not legal if there's a repeated digit
		return @@is_legal_answer[x] if @@is_legal_answer[x]
		h = {}
		# debug "LEGAL? #{x}"
		stringify_index(x).each_char do |char|
			# print "#{char} "
			@@is_legal_answer[x] = false
			return false if (h[char]) #found repeat!
			h[char] = true
		end
		# debug "LEGAL!"
		@@is_legal_answer[x] = true
		return true
	end

	@@stringify_index = {}
	def stringify_index(x)
		@@stringify_index[x] ||= x.to_s.rjust(@num_digits,'0')
	end

end


cow_bull = CowBull.new
cow_bull.play_with_myself
