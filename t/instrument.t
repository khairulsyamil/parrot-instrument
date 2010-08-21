#!./parrot
# Copyright (C) 2010, Parrot Foundation.
# $Id: instrument.t 48268 2010-08-03 03:23:30Z khairul $

=head1 NAME

t/dynpmc/instrument.t - test the Instrument dynpmc

=head1 SYNOPSIS

        % prove t/dynpmc/instrument.t

=head1 DESCRIPTION

Tests the low level interface provided by instrument.pmc.

=cut

.sub main :main
    .include 'test_more.pir'

    # Load the Instrument library.
    load_bytecode 'Instrument/InstrumentLib.pbc'

    plan(18)
    test_loadlib()
    test_instantiate()
    test_attach()
    test_insert_and_remove_op_hook()
    test_insert_and_remove_op_catchall()

    .return()
.end

.sub 'test_loadlib'
    .local pmc lib

    lib = loadlib 'instrument_group'
    $I0 = defined lib
    ok($I0, 'Instrument dynpmc loaded')

    .return()

.end

.sub 'test_instantiate'
    .local pmc instr

    instr = new ['Instrument']
    $I0 = defined instr
    ok($I0, 'Instrument object instantiated')

.end

.sub 'test_attach'
    .local pmc mock_probe, instr

    mock_probe = new ['MockProbe']

    instr      = new ['Instrument']
    instr.'attach'(mock_probe)

.end

.sub 'test_insert_and_remove_op_hook'
    # Plan: Test insertion and removal of hooks.
    .local pmc instr, instrument
    .local pmc probe1, probe2

    probe1     = new ['MockProbe']
    probe2     = new ['MockProbe']
    instrument = new ['Instrument']
    instr      = instrument['runcore']

    # Test insert and remove 1 hook on existing op (op 0 = noop).
    instr.'insert_op_hook'(probe1, 0)
    $I0 = instr.'count_op_hooks'(0)
    is($I0, 1, 'Insertion successful')

    instr.'remove_op_hook'(probe1, 0)
    $I0 = instr.'count_op_hooks'(0)
    is($I0, 0, 'Removal successful')

    # Test insert and removal 2 hooks on existing op.
    instr.'insert_op_hook'(probe1, 0)
    instr.'insert_op_hook'(probe2, 0)
    $I0 = instr.'count_op_hooks'(0)
    is($I0, 2, 'Insertion successful')

    instr.'remove_op_hook'(probe1, 0)
    $I0 = instr.'count_op_hooks'(0)
    is($I0, 1, 'Removal of probe 1 successful')

    instr.'remove_op_hook'(probe2, 0)
    $I0 = instr.'count_op_hooks'(0)
    is($I0, 0, 'Removal of probe 2 successful')

    # Test insertion on a non-existent op. (Say, op 5000)
    .local pmc eh
    eh = new ['ExceptionHandler']
    set_addr eh, NON_EXIST_OP_OK
    push_eh eh

    instr.'insert_op_hook'(probe1, 5000)

    ok(0, 'Managed to insert probe for non-existent op.')
    goto NON_EXIST_OP_END

  NON_EXIST_OP_OK:

    ok(1, 'Detected non-existent op')

  NON_EXIST_OP_END:

    pop_eh

    # Test removal of non-existent hook.
    eh = new ['ExceptionHandler']
    set_addr eh, NON_EXIST_PROBE_OK
    push_eh eh

    instr.'remove_op_hook'(probe1, 0)

    ok(0, 'Managed to remove non-existent probe.')
    goto NON_EXIST_PROBE_END

  NON_EXIST_PROBE_OK:

    ok(1, 'Detected non-existent probe')

  NON_EXIST_PROBE_END:

    pop_eh

.end

.sub 'test_insert_and_remove_op_catchall'
    # Plan: Test insertion and removal of catchall probes.
    .local pmc instr, instrument
    .local pmc probe1, probe2

    probe1 = new ['MockProbe']
    probe2 = new ['MockProbe']
    instrument = new ['Instrument']
    instr      = instrument['runcore']

    # Test insert and remove 1 catchall.
    instr.'insert_op_catchall'(probe1)
    $I0 = instr.'count_op_catchalls'()
    is($I0, 1, 'Insertion of catchall successful')

    instr.'remove_op_catchall'(probe1)
    $I0 = instr.'count_op_catchalls'()
    is($I0, 0, 'Removal of catchall successful')

    # Test insert and removal 2 catchalls.
    instr.'insert_op_catchall'(probe1)
    instr.'insert_op_catchall'(probe2)
    $I0 = instr.'count_op_catchalls'()
    is($I0, 2, 'Insertion of catchalls successful')

    instr.'remove_op_catchall'(probe1)
    $I0 = instr.'count_op_catchalls'()
    is($I0, 1, 'Removal of catchall probe 1 successful')

    instr.'remove_op_catchall'(probe2)
    $I0 = instr.'count_op_catchalls'()
    is($I0, 0, 'Removal of catchall probe 2 successful')

    # Test removal of non-existent catchall hook.
    .local pmc eh
    eh = new ['ExceptionHandler']
    set_addr eh, NON_EXIST_CATCHALL_OK
    push_eh eh

    instr.'remove_op_catchall'(probe1)

    ok(0, 'Managed to remove non-existent probe.')
    goto NON_EXIST_CATCHALL_END

  NON_EXIST_CATCHALL_OK:

    ok(1, 'Detected non-existent probe')

  NON_EXIST_CATCHALL_END:

    pop_eh

.end

#
# Simple Mock of Instrument::Probe to test
#  attach.
#
.namespace ['MockProbe']
.sub '' :anon :init :load
    .local pmc class
    class = newclass ['MockProbe']
    addattribute class, '$!instr_obj'
    addattribute class, '$!identifier'

    $P0 = box 0
    set_hll_global "$MockProbe-count", $P0
.end

.sub 'init' :vtable :method
    $P1 = get_hll_global "$MockProbe-count"
    inc $P1
    set_hll_global "$MockProbe-count", $P1

    $P0 = new ['String']
    $P0 = 'MockProbe-'
    $P0 .= $P1
    setattribute self, '$!identifier', $P0
.end

.sub '_on_attach' :method
    ok(1, 'Enable is called')

    .local pmc instr_obj
    .local string instr_obj_type
    instr_obj = getattribute self, '$!instr_obj'
    $I0 = defined instr_obj
    ok($I0, 'Attribute instr_obj is defined')

    instr_obj_type = typeof instr_obj
    is(instr_obj_type, 'Instrument', 'Attribute instr_obj is the correct type')

    .return()
.end

.sub 'disable' :method
.end

# Local Variables:
#   mode: pir
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4 ft=pir:
