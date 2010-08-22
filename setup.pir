
.sub main :main
    .param pmc args

    # Get self
    .local string me
    me = shift args

    load_bytecode 'distutils.pbc'

    .local pmc config, pmcs

    # Setup config.
    config = new ['Hash']
    config['name']     = 'parrot-instruments'
    config['abstract'] = 'Instrument framework for Parrot VM'

    # Setup pmcs
    $P0  = split "\n", <<'PMCS'
src/dynpmc/instrument.pmc
src/dynpmc/instrumentop.pmc
src/dynpmc/instrumentstubbase.pmc
src/dynpmc/instrumentinvokable.pmc
src/dynpmc/instrumentruncore.pmc
src/dynpmc/instrumentgc.pmc
src/dynpmc/instrumentclass.pmc
src/dynpmc/instrumentobject.pmc
PMCS
    $S0 = pop $P0

    pmcs = new ['Hash']
    pmcs['instrument_group'] = $P0

    config['dynpmc']        = pmcs
    config['dynpmc_cflags'] = "-g"

    setup(args :flat, config :flat :named)
.end