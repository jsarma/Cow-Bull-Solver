
require 'optparse'
require 'ruby-prof'

def main
	options = {
		digits: 3,
		mode: 'play'
	}
	OptionParser.new do |opts|
	  opts.banner = "Usage: cow_bull.rb [options]"

	  opts.on("-D", "--debug", "Run In Debug Mode") do |arg|
	    options[:debug] = arg
	  end

	  opts.on("-mMODE", "--mode=MODE", "Executation mode: (play, solve, load") do |arg|
	    options[:mode] = arg
	  end

	  opts.on("-dDIGIT", "--digits=DIGIT", "Number of digits") do |arg|
	    options[:digits] = arg.to_i
	  end

	end.parse!

	puts options

	#we need some command line option parsing don't we!
	case options[:mode]
	when 'play'
		cow_bull = CowBull.new
		cow_bull.play(options)
	when 'solve'
		cow_bull = CowBull.new
		cow_bull.play_with_myself(options)
	when 'load' #TODO: just load the code to call functions from outside
	end
end


class CowBull
	@@level = 0

	def debug(msg, level=1)
		puts msg if (level <= @@level)
	end 

	def setup(options)
		@num_digits = options[:digits] || 3
		@done_state = @num_digits * 10;
		@n = (10 ** @num_digits) #max possible guess. min is always 0
		@n = 25		
		debug "N: #{@n}"
		filename = "cow_bull_#{@num_digits}.matrix";
		if (File.exists?(filename))
			puts "Cached response matrix exists"
			@src_matrix = Marshal.load(File.binread(filename))
		else
			puts "Not cached response matrix. Must generation. Long time..."
			@src_matrix = init_matrix
			File.open(filename, 'wb') {|f| f.write(Marshal.dump(@src_matrix))}
		end
	end

	#Play our algorithm for every possible answer.
	def play_with_myself(options)
		game_scores = []
		game_score_sequences = {}
		setup(options)
		@matrix = @src_matrix
		#ser_matrix = Marshal.dump(@src_matrix)
		#play once for each possible correct answer
		@n.step(0, -1) do |secret| #go in reverse because higher numbers are harder and we want bad results quick
			next if (!is_legal_answer(secret))
			#@matrix = Marshal.load(ser_matrix)
			@eliminated = {}
			@guessed = {}
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
				game_score_sequences[secret].push(stringify_index(guess))

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

	#play our algorithm for a specific answer, interactively with user.
	def play(options)
		setup(options)
		#print_matrix
		@matrix = @src_matrix
		@eliminated = {}
		@guessed = {}
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

	#populate the initial game matrix:
	#(Guess, Possible Correct Answer) = response(guess, possible correct answer)
	#eg: "if I guess, 1234, and the correct answer is 3456, we set the value at (1234,3456) = 02, for 2 cows"
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
				next if (col==-1 || @eliminated[col_index])
				debug "(#{stringify_index(row_index)}, #{stringify_index(col_index)}): #{col}", 1
			end
		end

	end

	#Every iteration, we update the matrix by removing answers that are no longer possible
	def update_matrix(guess, response)
		debug "UPDATE_MATRIX: #{guess}, #{response}", 2
		#eliminate all answers that this response renders invalid
		@matrix[guess].each_with_index do |col, col_index|
			next if (col == -1 || @eliminated[col_index])
			if (response != col)
				debug "MARKING (#{guess}, #{col_index})", 2
				@eliminated[col_index] = true
				#remove this answer from all future guess calculations
				# @matrix.each_with_index do |row, row_index|
				# 	next if (@matrix[row_index] == -1)
				# 	@matrix[row_index][col_index] = -1
				# end
			end
		end
		#don't try the same guess twice
		#@matrix[guess.to_i] = -1
		@eliminated[guess] = true
		@guessed[guess] = true
	end

	#Use the existing matrix to calculate and return the guess that will eliminate the most possible answers
	#The heuristic we use is to count the total number of possible answers the most likely response would eliminate
	#This requires us figure out the most likely response and remove it from the count.
	#Example: If a certain guess could generate 40 responses depending on remaining possible correct answers: 
	#  12: 2 bulls
	#  10: 1 cow 1 bull
	#   8: 1 cow
	#   5: 2 cows
	#   5: none
	#We would add these up (40), then subtract off the most common one (12), giving us 28 as the score of this guess.
	#When we get the response, we can eliminate any answer that does not match. So if they respond 2 bulls,
	#we know we can eliminate 28 possibilities. And any other response would eliminate at least 28 possibilities,
	#because every other set is smaller than 12.
	#So by maximizing this score, we are maximizing the worst case number of possibilities we will eliminate.
	def compute_guess
		best_guess_score = 0
		best_guess_index = -1
		@matrix.each_with_index do |row, row_index|
			next if (row == -1 || @guessed[row_index])  #skip illegal and already guessed answers
			x = {}
			score = 0
			row.each_with_index do |col, col_index|
				next if (col == -1 || @eliminated[col_index]) #skip illegal and eliminated possibilities
				x[col] ||= 0
				x[col] += 1
				score += 1
			end
			prescore = score
			if (x.size==0) #no solution
				return -1
			elsif (x.size==1)
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

	# Given a guess and an answer, calculate the correct game response.
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

	@@is_legal_answer = {} #cache so it's quicker!
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

	@@stringify_index = {} #cache so it's quicker!
	def stringify_index(x)
		@@stringify_index[x] ||= x.to_s.rjust(@num_digits,'0')
	end


	#Output stats at the end.
	def score_algorithm(game_scores, game_score_sequences)
		#puts "Guess Sequences: #{game_score_sequences}"
		#puts "Scores: #{game_scores}"
		puts "Max Guesses: #{game_scores.max_by {|k,v| v} }"
		puts "Avg Guesses: #{game_scores.inject(0.0) { |sum, el| sum + el[1] } / game_scores.size }"
	end

	#WIP - Figure out a clean way to turn game_score_sequences into a decision tree
	#5312      [1234, {3: [5678, ]
	#[guess, {response => [guess]}]
	# def construct_decision_tree(game_score_sequences)
	# 	tree = []
	# 	node = tree
	# 	game_score_sequences.each do |secret, sequence|
	# 		sequence.each do |guess|
	# 			if (node.size==0)
	# 				node.push(guess)
	# 				response = respond(guess, secret)
	# 				node.push({response => []})
	# 			end
	# 			node = node[1][response]
	# 		end
	# 	end
	# 	tree.inspect
	# end
end

#RubyProf.start
main
#result = RubyProf.stop
#printer = RubyProf::FlatPrinter.new(result)
#printer.print(STDOUT)

