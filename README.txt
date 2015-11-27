                  ██████╗ ███╗   ██╗██╗ ██████╗ ███╗   ███╗ 
                 ██╔═══██╗████╗  ██║██║██╔═══██╗████╗ ████║ 
                 ██║   ██║██╔██╗ ██║██║██║   ██║██╔████╔██║ 
                 ██║   ██║██║╚██╗██║██║██║   ██║██║╚██╔╝██║ 
                 ╚██████╔╝██║ ╚████║██║╚██████╔╝██║ ╚═╝ ██║ 
                  ╚═════╝ ╚═╝  ╚═══╝╚═╝ ╚═════╝ ╚═╝     ╚═╝ 

  █████╗ ███╗   ██╗ █████╗ ██╗  ██╗   ██╗███████╗██╗███████╗
 ██╔══██╗████╗  ██║██╔══██╗██║  ╚██╗ ██╔╝██╔════╝██║██╔════╝
 ███████║██╔██╗ ██║███████║██║   ╚████╔╝ ███████╗██║███████╗
 ██╔══██║██║╚██╗██║██╔══██║██║    ╚██╔╝  ╚════██║██║╚════██║
 ██║  ██║██║ ╚████║██║  ██║███████╗██║   ███████║██║███████║
 ╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝╚══════╝╚═╝   ╚══════╝╚═╝╚══════╝

Script developed by Henrique Silva Fernandes (henrique.fernandes@fc.up.pt | henriquefer11@gmail.com)

oniomANALYSIS allows collect information about Gaussian 09 output files (.log):
	— Energy of Low and High Level as well as Total Energy
		2 files:
				- Energy of all structures
				- Energy of optimized sutructures
	- Gaussian input files ready to strat another calculation
		2 files:
				- File with initial atomic coordinates
				- File with last atomic coordinates
	- PDB files
		4 files:
				- File with all structures
				- File with optimized structures
				- File with last structure
				- File with last optimized structure


How to use: 
	Insert follow command in shell:
		> tclsh oniomANALYSIS.tcl [A] [B]

	Where:
		[A] is a flag which defines what type of job is going to be perfomed:
			--energy 	: for energy extraction
			--gaussian 	: for Gaussian input files generation
			--pdb 		: for PDB files generation

		[B] is the Gaussian 09 output file (.log)

	For example:
		> tclsh oniomANALYSIS.tcl --energy scan.log
		or
		> tclsh oniomANALYSIS.tcl --pdb optimization.log


Todos os direitos reservados. 2015
——————————————————————————————————————————————————————————————————————————————————————————————————————