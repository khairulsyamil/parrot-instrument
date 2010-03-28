#include <parrot/parrot.h>
#include <parrot/embed.h>
#include <parrot/extend.h>
#include <parrot/runcore_api.h>
#include <parrot/imcc.h>

//Prototypes
static opcode_t *
runops_instr_core(Parrot_Interp interp, Parrot_runcore_t *runcore, opcode_t *pc);

//Instrument registry.
typedef struct _instrument_pmc_table {
	Parrot_PMC init;  // Called before executing code.
	Parrot_PMC exit;  // Called after code executes.
	Parrot_PMC counter; // Called by the runcore.
} Instr_pmc_table;

//Globals.
Parrot_Interp code_interp, instruments_interp;
Instr_pmc_table tb = {0}; // I think PMCs are pointers. So setting it to NULL should be ok right?

int main (int argc, char ** argv) {
	Parrot_String str;

	//Initialise both interpreters.
	instruments_interp = Parrot_new(NULL);
	code_interp = Parrot_new(instruments_interp);
	
	//Initialise imcc for both interpreters.
	imcc_initialize(instruments_interp);
	imcc_initialize(code_interp);
	
	imcc_start_handling_flags(instruments_interp);
	imcc_start_handling_flags(code_interp);
	
	//Assert that both interpreters initialized correctly.
	//... Later
	
	/* How to hijack the runcore of a?
	 * Looking at cores.c, the slow core is the simplest.
	 * So we shall ensure that the code interpreter initialises
	 * that core.
	 *
	 * With the runcore_t set, simply changing the function pointer
	 * for the runcore should do the trick.
	 *
	 * It is not a good thing to do, but I don't want to recreate
	 * a runcore for now. For the proof of concept, all I want to
	 * do is intercept the instruction before it is executed.
	 */
	Parrot_set_run_core(code_interp, PARROT_SLOW_CORE); // <- Set to slow core.
	code_interp->run_core->runops = runops_instr_core;  // <- Then we hijack.
	
	/* Now that both interpreters are initialized,
	 * its time to load up the files.
	 *
	 * Keep it simple for now.
	 * argv[1] = instruments
	 * argv[2] = source code
	 */
	
	//Load up the instruments.
	imcc_run(instruments_interp, argv[1], 1, argv + 1);
	
	//Scan the instruments.
	// (So far I only have instruction counter)
	str = string_from_literal(instruments_interp, "instr_init");
	tb.init = Parrot_find_global_cur(instruments_interp, str);
	str = string_from_literal(instruments_interp, "instr_exit");
	tb.exit = Parrot_find_global_cur(instruments_interp, str);
	str = string_from_literal(instruments_interp, "instr_instruction_counter");
	tb.counter = Parrot_find_global_cur(instruments_interp, str);
	
	//Load up the code and run.
	imcc_run(code_interp, argv[2],  argc - 2, argv + 2);
	
	//Ask the instruments to report.
	Parrot_ext_call(instruments_interp, tb.exit, "->");
	
	//Done.
	Parrot_destroy(code_interp);
	Parrot_destroy(instruments_interp);

	return 0;
}

static opcode_t *
runops_instr_core(Parrot_Interp interp, Parrot_runcore_t *runcore, opcode_t *pc) {

	while (pc) {
        /*if (pc < code_start || pc >= code_end)
            Parrot_ex_throw_from_c_args(interp, NULL, 1,
										"attempt to access code outside of current code segment");*/
		// ^ where does code_start and code_end come from?
		
        Parrot_pcc_set_pc(interp, CURRENT_CONTEXT(interp), pc);
		
		//Dispatch the instruments.
		// Well, for now we just have 1 instrument.
		Parrot_ext_call(
			instruments_interp,
			tb.counter,
			"S->",
			Parrot_str_new(
				instruments_interp,
				interp->op_info_table[*pc].full_name,
				0
			)
		);
		//printf("Doctor: Instruction == %s\n", interp->op_info_table[*pc].full_name);
		
        DO_OP(pc, interp);
    }
	
    return pc;
}