#### Time #####
	proc duration { secs } {
     set timeatoms [ list ]
     if { [ catch {
        foreach div { 86400 3600 60 1 } \
                mod { 0 24 60 60 } \
               name { day hour min sec } {
           set n [ expr {$secs / $div} ]
           if { $mod > 0 } { set n [ expr {$n % $mod} ] }
           if { $n > 1 } {
              lappend timeatoms "$n ${name}s"
           } elseif { $n == 1 } {
             lappend timeatoms "$n ${name}"
           }
        }
     } err ] } {
        return -code error "duration: $err"
     }
     return [ join $timeatoms ]
	}

	proc tempo {time0 time1} {
       ## transformar o tempo num integer
       scan "$time0" "%dh %dm %ds   %s %s %s" h0 m0 s0 mt0 d0 y0
       scan "$time1" "%dh %dm %ds   %s %s %s" h1 m1 s1 mt1 d1 y1
       set time0 [clock scan "$h0:$m0:$s0 $mt0 $d0 $y0"]
       set time1 [clock scan "$h1:$m1:$s1 $mt1 $d1 $y1"]
       ## contas de diferença do tempo
       set timeD [expr abs ($time0-$time1)]
       set timeDiff "1 secs"
       if {$timeD!=0} {set timeDiff [duration $timeD]}
       return $timeDiff
	}

proc rootName {File} \
{
	global fileName
	set fileName [file rootname $File]
	return $fileName
}

proc deleteTmpFiles {fileName} {
  file delete -force "ANALYSIStmpFiles"
}

#### ENERGY Calculations ####
	proc gettingEnergy {fileName File} {
		exec egrep {low   system:  model energy:|high  system:  model energy:|low   system:  real  energy:|ONIOM: extrapolated energy|Optimized Parameters} $File > ANALYSIStmpFiles/energy_$fileName.tmp
	}

	proc allEnergy {fileName} {
	set openFile [open "ANALYSIStmpFiles/energy_$fileName.tmp" r]
	set readFile [read $openFile]
	set outputFile [open "ENERGY-All-$fileName.txt" w]
	set outputTmpFile [open "ANALYSIStmpFiles/optimizedEnergy_$fileName.tmp" w]
	set lines [split $readFile \n]
	puts $outputFile "\n\t\t\t\t Energy of all structures\n"
	set header1 "|| LOW Model Energy /hartree||"
	set header2 "|| HIGH Model Energy /hartree||"
	set header3 "|| LOW Real Energy /hartree||"
	set header4 "|| TOTAL Energy /hartree||"
	puts $outputFile "[format %30s $header1] [format %30s $header2] [format %30s $header3] [format %30s $header4]"
	foreach line $lines {
		lassign $line column1 column2 column3 column4 column5 column6 column7 column8 value
		if {$column3 == 1} {
			puts -nonewline $outputFile "[format %30s $value]"
			puts -nonewline $outputTmpFile "\n $value"
		} elseif {$column3 == 2} {
			puts -nonewline $outputFile "[format %30s $value]"
			puts -nonewline $outputTmpFile " $value "
		} elseif {$column3 == 3} {
			puts -nonewline $outputFile "[format %30s $value]"
			puts -nonewline $outputTmpFile " $value "
		} elseif {$column2 == "extrapolated"} {
			puts -nonewline $outputFile "[format %30s $column5]\n"
			puts -nonewline $outputTmpFile " $column5 "
		} elseif {[regexp {Optimized} $line -> optimizedLine]} {
			set optimized "optstucture"
			puts -nonewline $outputTmpFile " $optimized"
		}
	}

	close $outputFile
	close $openFile
	close $outputTmpFile
	}

	proc optimizedEnergy {fileName} {
	set openFile [open "ANALYSIStmpFiles/optimizedEnergy_$fileName.tmp" r]
	set readFile [read $openFile]
	set outputFile [open "ENERGY-Opt-$fileName.txt" w]
	set lines [split $readFile \n]
	puts $outputFile "\n\t\t\t\t Energy of Optimized structures\n"
	set header1 "|| LOW Model Energy /hartree||"
	set header2 "|| HIGH Model Energy /hartree||"
	set header3 "|| LOW Real Energy /hartree||"
	set header4 "|| TOTAL Energy /hartree||"
	puts $outputFile "[format %30s $header1] [format %30s $header2] [format %30s $header3] [format %30s $header4]"
	foreach line $lines {
		if {[regexp {optstucture} $line -> foundOPT]} {
			lassign $line column1 column2 column3 column4
			puts $outputFile "[format %30s $column1] [format %30s $column2] [format %30s $column3] [format %30s $column4]"
		}
	}
	close $outputFile
	close $openFile
	}

#### Gaussian Files ####
	proc gettingGeneralInformation {fileName File} {
		exec egrep {PDBName} $File > ANALYSIStmpFiles/allGeneralInformation_$fileName.tmp
	}

	proc initialStructureGaussian {fileName File} {
		global listAllInfo listFrozenStatus listLayer listBorderAtom listBorderAtomNumber listPointOne listPointTwo
		set openFile [open "ANALYSIStmpFiles/allGeneralInformation_$fileName.tmp" r]
		set readFile [read $openFile]
		set outputFile [open "GAUSSIAN-Initial-$fileName.com" w]
		set lines [split $readFile \n]
		set optionsCalculation [exec egrep -A 3 " # " $File | egrep -v {\-\-|\s1}]
		puts $outputFile "%chk=gauInitial$fileName.chk"
		puts $outputFile "$optionsCalculation"
		puts $outputFile "\n Title    File extracted with oniomANALYSIS\n"
		set globalChargesSpin [exec egrep -A 3 "Symbolic Z-matrix" $File | egrep -v "Symbolic Z-matrix"]
		set lines1 [split $globalChargesSpin \n]
		  foreach line1 $lines1 {
		    set charge [string range $line1 9 11]
		    set spin [string index $line1 28]
		    puts -nonewline $outputFile "$charge $spin"
		  }
		puts $outputFile ""
		foreach line $lines {
			lassign $line allInfo frozenStatus xx yy zz layer borderAtom borderAtomNumber pointOne pointTwo
			puts $outputFile " [format %-60s $allInfo] [format %-4s $frozenStatus] [format "%10s"  [format %-7s $xx]] [format "%10s"  [format %-7s $yy]] [format "%10s"  [format %-7s $zz]] [format %-2s $layer] $borderAtom $borderAtomNumber   $pointOne $pointTwo"
			lappend listAllInfo $allInfo
			lappend listFrozenStatus $frozenStatus
			lappend listLayer $layer
			lappend listBorderAtom $borderAtom
			lappend listBorderAtomNumber $borderAtomNumber
			lappend listPointOne $pointOne
			lappend listPointTwo $pointTwo
		}
		close $openFile
		close $outputFile
	}

	proc lastStructureGaussian {fileName File listAllInfo listFrozenStatus listLayer listBorderAtom listBorderAtomNumber listPointOne listPointTwo} {
		set numberAtoms [exec grep -c ^ ANALYSIStmpFiles/allGeneralInformation_$fileName.tmp]
		set finalline [expr int($numberAtoms + 4)]
		exec egrep -A $finalline "Standard ori" $File > ANALYSIStmpFiles/coordinatesFromLastStrcuture_$fileName.tmp | tail -n $numberAtoms
		set openFile [open "ANALYSIStmpFiles/coordinatesFromLastStrcuture_$fileName.tmp" r]
		set readFile [read $openFile]
		set outputFile [open "GAUSSIAN-Last-$fileName.com" w]
		set lines [split $readFile \n]
		set optionsCalculation [exec egrep -A 3 " # " $File | egrep -v {\-\-|\s1}]
		puts $outputFile "%chk=gauLast$fileName.chk"
		puts $outputFile "$optionsCalculation"
		puts $outputFile "\n Title    File extracted with oniomANALYSIS\n"
		set globalChargesSpin [exec egrep -A 3 "Symbolic Z-matrix" $File | egrep -v "Symbolic Z-matrix"]
		set lines1 [split $globalChargesSpin \n]
		  foreach line1 $lines1 {
		    set charge [string range $line1 9 11]
		    set spin [string index $line1 28]
		    puts -nonewline $outputFile "$charge $spin"
		  }
		puts $outputFile ""
		foreach line $lines {
			lassign $line atomindexCoord atomicNumber randomNumber xx yy zz
			set listSearch [expr int($atomindexCoord - 1)]
			set allInfo [lindex $listAllInfo $listSearch]
			set frozenStatus [lindex $listFrozenStatus $listSearch]
			set layer [lindex $listLayer $listSearch]
			set borderAtom [lindex $listBorderAtom $listSearch]
			set borderAtomNumber [lindex $listBorderAtomNumber $listSearch]
			set pointOne [lindex $listPointOne $listSearch]
			set pointTwo [lindex $listPointTwo $listSearch]
			puts $outputFile " [format %-60s $allInfo] [format %-4s $frozenStatus] [format "%10s"  [format %-7s $xx]] [format "%10s"  [format %-7s $yy]] [format "%10s"  [format %-7s $zz]] [format %-2s $layer] $borderAtom $borderAtomNumber   $pointOne $pointTwo"
		}
		close $openFile
		close $outputFile
	}

#### PDB Files ####
	proc grepInitialFile {File fileName} {
		set firstdata [exec egrep {PDBName=} $File > ANALYSIStmpFiles/General_Information_$fileName.tmp]
	}

	proc numberAtoms {fileName} {
		global numberAtoms
		set numberAtoms [exec grep -c ^ ANALYSIStmpFiles/General_Information_$fileName.tmp]
	}

	proc getCoordinates {numberAtoms File fileName} {
		set finalline [expr int($numberAtoms + 5)]
		exec egrep -A $finalline "Standard orientation:" $File > ANALYSIStmpFiles/coordinates_$fileName.tmp | egrep -v {Center|Number|\-\-\-}
	}

	proc generalInformation {fileName numberAtoms Frozen} {
		set geralInfo [open "ANALYSIStmpFiles/General_Information_$fileName.tmp" r]
		set geralInfoData [read $geralInfo]
	  set numberAtoms $numberAtoms
	  set Frozen $Frozen
		set lines [split $geralInfoData \n]
		foreach line $lines {
			lassign $line column1 frozenStatus xInitial yInital zInitial layer
	  		incr atomindex
	  		set searchline [regexp {(\S+)[-](\S+)[-](\S+)[(]PDBName=(\S+),ResName} $line -> atomsymbol atomGaussianType charges atomPDBType]
	  		set searchline1 [regexp {ResName=(\S+),} $line -> resName]
	  		set searchline2 [regexp {ResNum=(\S+)[)]} $line -> resid]
	  		lappend listAtomindex $atomindex
	  		lappend listAtomPDBType $atomPDBType
	  		lappend listResname $resName
	  		lappend listLayer $layer
	  		lappend listResid $resid
	      	lappend listColumn1 $column1
	      	lappend listFrozenstatus $frozenStatus
			lappend listX $xInitial
			lappend listY $yInital
			lappend listZ $zInitial
			lappend	listAtomSymbol $atomsymbol
			if {[string match "*--*" $line]==1} {
				lappend listCharges "-$charges"
			} else {
				lappend listCharges "$charges"
			}
		}
		allStructuresPDBFile $fileName $listAtomPDBType $listResname $listLayer $listResid $listAtomSymbol
	}

	proc allStructuresPDBFile {fileName listAtomPDBType listResname listLayer listResid listAtomSymbol} {
	  set numberLines [exec grep -c ^ ANALYSIStmpFiles/coordinates_$fileName.tmp]
	  set coordinatesFile [open "ANALYSIStmpFiles/coordinates_$fileName.tmp"]
	  set allStructuresPDBFile [open "PDB-All-Structures-$fileName.pdb" w]
	  while {[gets $coordinatesFile line] >= 0} {
	        if {[regexp {Standard} $line -> foundStandard]} {
	        incr structureNumber
	        puts $allStructuresPDBFile "HEADER\nStructure $structureNumber"
	      } elseif {[regexp {[-][-]} $line -> foundTrace]} {
	        puts $allStructuresPDBFile "END"
	     } else {
	        lassign $line atomindexCoord atomicNumber randomNumber xxx yyy zzz
	        set listSearch [expr int($atomindexCoord - 1)]
	        set atomPDBType [lindex $listAtomPDBType $listSearch]
	        set resName [lindex $listResname $listSearch]
	        set layer [lindex $listLayer $listSearch]
	        set resid [lindex $listResid $listSearch]
	        set atomSymbol [lindex $listAtomSymbol $listSearch]
	        set xx [regexp {(\S+)\.+(\S+)} $xxx -> xbefore xafter]
	        set x $xbefore\.[format %.3s $xafter]
	        set yy [regexp {(\S+)\.+(\S+)} $yyy -> ybefore yafter]
	        set y $ybefore\.[format %.3s $yafter]
	        set zz [regexp {(\S+)\.+(\S+)} $zzz -> zbefore zafter]
	        set z $zbefore\.[format %.3s $zafter]
	        puts $allStructuresPDBFile "[format %-4s "ATOM"] [format %6s $atomindexCoord] [format %-4s $atomPDBType][format %4s $resName] [format %-1s $layer] [format %-7s $resid] [format %7s $x] [format %7s $y] [format %7s $z] [format %5s "1.00"] [format %-8s "00.00"] [format %8s $atomSymbol]"
	      }
	  }
	  close $coordinatesFile
	  puts $allStructuresPDBFile "END"
	  puts $allStructuresPDBFile "#########"
	  close $allStructuresPDBFile
	}

	proc optStructuresPDBFile {File fileName numberAtoms} {
	  set standardOrientation [exec egrep {Standard orientation:|Optimized Parameters} $File > ANALYSIStmpFiles/linenumber_strucutres_opt_$fileName.tmp]
	  set openFile [open "ANALYSIStmpFiles/linenumber_strucutres_opt_$fileName.tmp" r]
	  set readFile [read $openFile]
	  set lines1 [split $readFile \n]
	  foreach line1 $lines1 {
	  	set searchOptimized [regexp {Optimized} $line1]
	  }
	  if {$searchOptimized==1} {
		  set optimizedStructures [exec grep -n {Optimized Parameters} ANALYSIStmpFiles/linenumber_strucutres_opt_$fileName.tmp | cut -f1 -d:]
		  set outputfile [open "PDB-Optimized-Structures-$fileName.pdb" w]
		  set lines [split $optimizedStructures \n]
		  foreach line $lines {
		    incr i
		    set finalline [expr int($numberAtoms + 1)]
		    set structureOptimizedNumber [expr int($line - $i)]
		    exec egrep -A $finalline -B 1 "Structure [subst $structureOptimizedNumber]" PDB-All-Structures-$fileName.pdb > ANALYSIStmpFiles/all_optimized_PDB_$fileName.temp$i
		    exec cat ANALYSIStmpFiles/all_optimized_PDB_$fileName.temp$i >> PDB-Optimized-Structures-$fileName.pdb
		    file delete "all_optimized_PDB_$fileName.temp$i"
	    }  
	    exec egrep -A $finalline -B 1 "Structure [subst $structureOptimizedNumber]" PDB-All-Structures-$fileName.pdb > PDB-Last-Optimized-Structure-$fileName.pdb
	}
	close $openFile
	}

	proc lastStructurePDBFile {numberAtoms fileName} {
	  set initialline [expr int($numberAtoms + 3)]
	  exec egrep -B $initialline "#########" PDB-All-Structures-$fileName.pdb > PDB-Last-Structure-$fileName.pdb
	}

######################################################################################################################################
##########                             STRAT     START     START     START     START     START     START               ###############
######################################################################################################################################
puts \n
puts "                         ██████╗ ███╗   ██╗██╗ ██████╗ ███╗   ███╗ "
puts "                        ██╔═══██╗████╗  ██║██║██╔═══██╗████╗ ████║ "
puts "                        ██║   ██║██╔██╗ ██║██║██║   ██║██╔████╔██║ "
puts "                        ██║   ██║██║╚██╗██║██║██║   ██║██║╚██╔╝██║ "
puts "                        ╚██████╔╝██║ ╚████║██║╚██████╔╝██║ ╚═╝ ██║ "
puts "                         ╚═════╝ ╚═╝  ╚═══╝╚═╝ ╚═════╝ ╚═╝     ╚═╝ "
puts "                                          Version 1.1 ◉ 27 NOV 2015"
puts "         █████╗ ███╗   ██╗ █████╗ ██╗  ██╗   ██╗███████╗██╗███████╗"
puts "        ██╔══██╗████╗  ██║██╔══██╗██║  ╚██╗ ██╔╝██╔════╝██║██╔════╝"
puts "        ███████║██╔██╗ ██║███████║██║   ╚████╔╝ ███████╗██║███████╗"
puts "        ██╔══██║██║╚██╗██║██╔══██║██║    ╚██╔╝  ╚════██║██║╚════██║"
puts "        ██║  ██║██║ ╚████║██║  ██║███████╗██║   ███████║██║███████║"
puts "        ╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝╚══════╝╚═╝   ╚══════╝╚═╝╚══════╝"
puts "        Developer: Henrique Fernandes (henrique.fernandes@fc.up.pt)"
puts "                    tclsh oniomANALYSIS --help for more information"
puts \n


### Load input information fom user ###
	file mkdir ANALYSIStmpFiles /
	set Options [lindex $argv 0]
	set File [lindex $argv 1]
	set Frozen [lindex $argv 2]

	if {[lindex $argv 0]== "--help" ||  $File==""} {
	        puts "  Usage:"
	        puts "  runs on the shell \n\t> tclsh oniomANALYSIS.tcl \[A\] \[B\]"
	        puts "  \[A\]: insert a flag to define what you want"
	        puts "			--energy : information about energy"
	        puts "			--gaussian : input Gaussian Files"
	        puts "			--pdb : pdb files with structures"
	        puts "			--all : do all above jobs"
	        puts "  \[B\]: .log file from Gaussian"
	        puts "\n"
	        puts " Developer: Henrique Fernandes   henrique.fernandes@fc.up.pt"
	        puts "\n"
	        exit
	}
	if {[lindex $argv 2]== ""} {
	  set fileFrozen [open "ANALYSIStmpFiles/file_empty.tmp" w]
	  puts $fileFrozen " "
	  close $fileFrozen
	  set Frozen "ANALYSIStmpFiles/file_empty.tmp"
	}

### Set fileName ###
rootName $File

### All Calculations ###
if {[lindex $argv 0]== "--all"} {
  	set time0 [clock format [clock seconds] -format "%Hh %Mm %Ss   %d %b %y"]

  	puts "\t Energy Calcuation"
	puts "\t Step 1 of 10: Reading all energy values from file..."
	gettingEnergy $fileName $File
	puts "\t Step 2 of 10: Writting energy of all structures..."
	allEnergy $fileName
	puts "\t Step 3 of 10: Writting energy of optimized structures..."
	optimizedEnergy $fileName
	puts \n
	puts "\t Gaussian Files"
	puts "\t Step 4 of 10: Getting General information about the system..."
	gettingGeneralInformation $fileName $File
	puts "\t Step 5 of 10: Writting Gaussian input file of initial structure..."
	initialStructureGaussian $fileName $File
	puts "\t Step 6 of 10: Writting Gaussian input file of last structure..."
	lastStructureGaussian $fileName $File $listAllInfo $listFrozenStatus $listLayer $listBorderAtom $listBorderAtomNumber $listPointOne $listPointTwo
	puts \n
	puts "\t PDB Files"
	puts "\t Step 7 of 10: Getting General information about the system..."
	grepInitialFile $File $fileName
	numberAtoms $fileName
	getCoordinates $numberAtoms $File $fileName
	puts "\t Step 8 of 10: Writting PDB file with all structures..."
	generalInformation $fileName $numberAtoms $Frozen
	puts "\t Step 9 of 10: Writting PDB file with optimized structures..."
	optStructuresPDBFile $File $fileName $numberAtoms
	puts "\t Step 10 of 10: Writting PDB file with last structure..."
	lastStructurePDBFile $numberAtoms $fileName

	after 2540
	set time1 [clock format [clock seconds] -format "%Hh %Mm %Ss   %d %b %y"]
	set result [tempo $time0 $time1]
	puts "\n\t Time spent: $result"

}

### Energy ###
if {[lindex $argv 0]== "--energy"} {
	set time0 [clock format [clock seconds] -format "%Hh %Mm %Ss   %d %b %y"]

	puts "\t Energy Calcuation"
	puts "\t Step 1 of 3: Reading all energy values from file..."
  	gettingEnergy $fileName $File
  	puts "\t Step 2 of 3: Writting energy of all structures..."
  	allEnergy $fileName
  	puts "\t Step 3 of 3: Writting energy of optimized structures..."
  	optimizedEnergy $fileName

  	after 2540
	set time1 [clock format [clock seconds] -format "%Hh %Mm %Ss   %d %b %y"]
	set result [tempo $time0 $time1]
	puts "\tTime spent: $result"
}

### Gaussian ###
if {[lindex $argv 0]== "--gaussian"} {
	set time0 [clock format [clock seconds] -format "%Hh %Mm %Ss   %d %b %y"]
  	
  	puts "\t Gaussian Files"
	puts "\t Step 1 of 3: Getting General information about the system..."
  	gettingGeneralInformation $fileName $File
  	puts "\t Step 2 of 3: Writting Gaussian input file of initial structure..."
  	initialStructureGaussian $fileName $File
  	puts "\t Step 3 of 3: Writting Gaussian input file of last structure..."
  	lastStructureGaussian $fileName $File $listAllInfo $listFrozenStatus $listLayer $listBorderAtom $listBorderAtomNumber $listPointOne $listPointTwo

	set time1 [clock format [clock seconds] -format "%Hh %Mm %Ss   %d %b %y"]
	set result [tempo $time0 $time1]
	puts "\t Time spent: $result"
}

### PDB ###
if {[lindex $argv 0]== "--pdb"} {
	set time0 [clock format [clock seconds] -format "%Hh %Mm %Ss   %d %b %y"]

	puts "\t PDB Files"
	puts "\t Step 1 of 4: Getting General information about the system..."
	grepInitialFile $File $fileName
	numberAtoms $fileName
	getCoordinates $numberAtoms $File $fileName
	puts "\t Step 2 of 4: Writting PDB file with all structures..."
	generalInformation $fileName $numberAtoms $Frozen
	puts "\t Step 3 of 4: Writting PDB file with optimized structures..."
	optStructuresPDBFile $File $fileName $numberAtoms
	puts "\t Step 4 of 4: Writting PDB file with last structure..."
	lastStructurePDBFile $numberAtoms $fileName

	set time1 [clock format [clock seconds] -format "%Hh %Mm %Ss   %d %b %y"]
	set result [tempo $time0 $time1]
	puts "\t Time spent: $result"
}

### Delete temporary files created above ###
deleteTmpFiles $fileName

### Jobs were done ###
puts \n
puts "\t All jobs were done succesfully. :\)"
puts \n