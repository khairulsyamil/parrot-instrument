.sub instr_init :main
	.local pmc hash
	$P0 = new 'Integer'
	hash = new ['Hash']
	set_global "$instruction_count", $P0
	set_global "$instruction_hash", hash
.end

.sub instr_exit
	get_global $P0, "$instruction_count"
	print "Instrumentation Report:\n\n"
	print "\tInstruction Counter : "
	print $P0
	print " instructions counted\n"
	print "\n"
	print "\tIndividual Instruction Counts :\n"
	dump_hash()
.end

.sub dump_hash
	.local pmc hash
	.local pmc it
	get_global hash, "$instruction_hash"
	it = iter hash
LOOP:	unless it goto L_END
	$P0 = shift it
	$P1 = $P0.'key'()
	$I0 = hash[$P1]
	
	print "\t\t"
	print $P1
	print " : "
	print $I0
	print "\n"
	goto LOOP
L_END:
.end

.sub instr_instruction_counter
	.param pmc instr_name
	.local pmc hash
	.local pmc counter

	get_global counter, "$instruction_count"
	get_global hash, "$instruction_hash"

	# Increment Instruction Count
	counter = counter + 1

	# Check if the instruction is defined in hash
	$P0 = hash[instr_name]
	$I0 = defined $P0
	if $I0 goto DEF
		$P0 = new 'Integer'
DEF:
	$P0 = $P0 + 1
	set hash[instr_name], $P0

	set_global "$instruction_count", counter
	set_global "$instruction_hash", hash
.end
