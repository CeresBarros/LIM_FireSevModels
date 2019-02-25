package ModulesV4::SK_conversion03UTM;


use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(&SKinv_to_CAS );

use strict;
use Text::CSV;
our $INV_version;
our $Species_table;	
use constant {
        INFTY =>-1,
        ERRCODE => -9999,
	SPECIES_ERRCODE => "XXXX ERRC",
	MISSCODE => -1111,
	UNDEF=> -8888
    };


our $Glob_CASID;
our $Glob_filename;	
#Derive SoilMoistureRegime from drainage class and unproductive wetland classes
sub SoilMoistureRegime{
	my $MoistReg;
	my %MoistRegList = ("", 1, "VR", 1, "VRR", 1, "R", 1, "RW", 1, "W", 1, "WMW", 1, "MW", 1, "MWD", 1,"MWI", 1, "I", 1, "IP", 1, "P", 1, "PD", 1,"PVP", 1, "VP", 1, 				   "VD", 1, "D", 1, "MF", 1, "F", 1, "VF", 1, "MM", 1, "M", 1, "VM", 1, "MW", 1, "W", 1, "VW", 1);
	my $SoilMoistureReg;

	($MoistReg) = shift(@_);
	$_ = $MoistReg; tr/a-z/A-Z/; $MoistReg = $_;
	if ($MoistRegList {$MoistReg} ) { } else {$SoilMoistureReg = ERRCODE; }

	if ($INV_version eq "UTM"){
					if (($MoistReg eq "VR"))         { $SoilMoistureReg = "D"; }
					elsif (($MoistReg eq "VRR"))         { $SoilMoistureReg = "D"; }
					elsif (($MoistReg eq "R"))         { $SoilMoistureReg = "D"; }
					elsif (($MoistReg eq "RW"))         { $SoilMoistureReg = "F"; }
					elsif (($MoistReg eq "W"))         { $SoilMoistureReg = "F"; }
					elsif (($MoistReg eq "WMW"))         { $SoilMoistureReg = "F"; }
					elsif (($MoistReg eq "MW"))         { $SoilMoistureReg = "F"; }
					elsif (($MoistReg eq "MWD"))         { $SoilMoistureReg = "F"; }
					elsif (($MoistReg eq "MWI"))         { $SoilMoistureReg = "M"; }
					elsif (($MoistReg eq "I"))         { $SoilMoistureReg = "M"; }
					elsif (($MoistReg eq "IP"))         { $SoilMoistureReg = "M"; }
					elsif (($MoistReg eq "P"))         { $SoilMoistureReg = "M"; }
					elsif (($MoistReg eq "PD"))         { $SoilMoistureReg = "M"; }
					elsif (($MoistReg eq "PVP"))         { $SoilMoistureReg = "W"; }
					elsif (($MoistReg eq "VP"))         { $SoilMoistureReg = "w"; }
					elsif  ($MoistReg eq "")         { $SoilMoistureReg = MISSCODE; }
	}
	elsif ($INV_version eq "SFVI"){
					if (($MoistReg eq "VD"))         { $SoilMoistureReg = "D"; }
					elsif (($MoistReg eq "D"))         { $SoilMoistureReg = "D"; }
					elsif (($MoistReg eq "MF"))         { $SoilMoistureReg = "F"; }
					elsif (($MoistReg eq "F"))         { $SoilMoistureReg = "F"; }
					elsif (($MoistReg eq "VF"))         { $SoilMoistureReg = "F"; }
					elsif (($MoistReg eq "MM"))         { $SoilMoistureReg = "M"; }
					elsif (($MoistReg eq "M"))         { $SoilMoistureReg = "M"; }
					elsif (($MoistReg eq "VM"))         { $SoilMoistureReg = "M"; }
					elsif (($MoistReg eq "MW"))         { $SoilMoistureReg = "W"; }
					elsif (($MoistReg eq "W"))         { $SoilMoistureReg = "W"; }
					elsif (($MoistReg eq "VW"))         { $SoilMoistureReg = "W"; }
					elsif  ($MoistReg eq "")    	{ $SoilMoistureReg = MISSCODE; }

	}
	else { $SoilMoistureReg = ERRCODE; }
	return $SoilMoistureReg;
}



sub StandStructure{
	my $Struc;
	my %StrucList = ("", 1,  "S", 1, "M", 1, "C", 1, "s", 1, "m", 1, "c", 1);
	my $StandStructure;

	($Struc) = shift(@_);
	if ($StrucList {$Struc} ) { } else {  $StandStructure = ERRCODE; }
	
	if($INV_version eq "SFVI"){
					if (($Struc eq ""))              			 { $StandStructure = "S"; }
					elsif (($Struc eq "s") || ($Struc eq "S"))               { $StandStructure = "S"; }
					elsif (($Struc eq "c") || ($Struc eq "C"))               { $StandStructure = "C"; }
					elsif (($Struc eq "m") || ($Struc eq "M"))               { $StandStructure = "M"; }
	}
	elsif($INV_version eq "UTM"){

					{ $StandStructure = "S"; }
	}
	else {  $StandStructure = ERRCODE; }

	return $StandStructure;
}

#Determine StandStructure from StrucVal
sub StandStructureValue{
	my $StrucVal;
	my  $StandStructureValue;

	($StrucVal) = shift(@_);
	if  ($StrucVal eq "")                                      { $StandStructureValue = 0; }
	elsif (($StrucVal < 1)    || ($StrucVal > 9))                 { $StandStructureValue = 0; }
	elsif (($StrucVal > 0)    && ($StrucVal < 10))                { $StandStructureValue = $StrucVal; }

	return $StandStructureValue;
}


#Determine CCUpper from CC 
sub CCUpper {
	my $CCHigh;
	my $Density;
	my %DensityList = ("", 1, "a", 1, "b", 1, "c", 1, "d", 1, "A", 1, "B", 1, "C", 1, "D", 1);

	($Density) = shift(@_);
	if ($INV_version eq "SFVI"){ 
						if($Density <=100 && $Density >=0) {$CCHigh =$Density;}
						else {$CCHigh= ERRCODE; }
	}
	elsif ($INV_version eq "UTM"){	

					if ($DensityList {$Density} ) { } else {$CCHigh= ERRCODE; }
					if ($Density eq "")                                       { $CCHigh = 0; }
					elsif (($Density eq "a") || ($Density eq "A"))            { $CCHigh = 30; }
					elsif (($Density eq "b") || ($Density eq "B"))            { $CCHigh = 55; }
					elsif (($Density eq "c") || ($Density eq "C"))            { $CCHigh = 80; }
					elsif (($Density eq "d") || ($Density eq "D"))            { $CCHigh = 100; }
	}
	return $CCHigh;
}

#Determine CCLower from CC
sub CCLower {
	my $CCLow;
	my $Density;
	my %DensityList = ("", 1, "a", 1, "b", 1, "c", 1, "d", 1, "A", 1, "B", 1, "C", 1, "D", 1);

	($Density) = shift(@_);
	if ($INV_version eq "SFVI"){ 
						if($Density <=100 && $Density >=0) {$CCLow =$Density;}
						else {$CCLow = ERRCODE; }
	}
	elsif ($INV_version eq "UTM"){
						if ($DensityList {$Density} ) { } else {$CCLow = ERRCODE; }
						if ($Density eq "")                                    { $CCLow = 0; }
						elsif (($Density eq "a") || ($Density eq "A"))            { $CCLow = 6; }
						elsif (($Density eq "b") || ($Density eq "B"))            { $CCLow = 31; }
						elsif (($Density eq "c") || ($Density eq "C"))            { $CCLow = 56; }
						elsif (($Density eq "d") || ($Density eq "D"))            { $CCLow = 81; }
	}
	return $CCLow;
}



#Determine stand height from HEIGHT	5   2.5 - 7.5	| 10   7.6-12.5	| 15  12.6 - 17.5  |	20   17.6 - 22.5 | 25    22.6-INFINITY	

sub StandHeightUp {
	my $Height;
	my %HeightList = ("", 1, "0", 1, "5", 1, "05", 1,"10", 1, "15", 1, "20", 1, "25", 1);
	my $HUpp;

	($Height) = shift(@_);	
	if ($INV_version eq "SFVI"){ 
						if($Height <=100 && $Height >0) {$HUpp =$Height+0.5;}
						else {$HUpp = ERRCODE; }
	}
	elsif ($INV_version eq "UTM"){

					if ($HeightList {$Height} ) { } else { $HUpp =ERRCODE; }
					if  ($Height eq "" || $Height eq "0")                   { $HUpp = MISSCODE; }
					elsif (($Height eq "25"))  		   { $HUpp = INFTY; }
					elsif (($Height eq "20"))                  { $HUpp = 22.5; }
					elsif (($Height eq "15"))                  { $HUpp = 17.5; }
					elsif (($Height eq "10"))                  { $HUpp = 12.5; }
					elsif (($Height eq "5")||($Height eq "05") )                   { $HUpp = 7.5; }
					#elsif (($Height eq "6"))                  { $HUpp = 4; }
	}

	return $HUpp;
}

#Determine lower bound stand height from HEIGHT  
sub StandHeightLow {
	my $Height;
	my %HeightList = ("", 1, "0", 1, "5", 1, "05", 1, "10", 1, "15", 1, "20", 1, "25", 1);
	my $HLow;

	($Height) = shift(@_);	
	if ($INV_version eq "SFVI"){ 
						if($Height <=100 && $Height >0) {

											if($Height >=0.5) {$HLow =$Height-0.5;}
											else {$HLow =$Height;}
						}
						else {$HLow = ERRCODE; }
	}
	elsif ($INV_version eq "UTM"){
						if ($HeightList {$Height} ) { } else { $HLow = ERRCODE; }
						if  ($Height eq "" || $Height eq "0")                    { $HLow = MISSCODE; }
						elsif (($Height eq "25"))  	       { $HLow = 22.6; }
						elsif (($Height eq "20"))                  { $HLow = 17.6; }
						elsif (($Height eq "15"))                  { $HLow = 12.6; }
						elsif (($Height eq "10"))                  { $HLow = 7.6; }
						elsif (($Height eq "5") || ($Height eq "05"))                   { $HLow = 2.6; }
						#elsif (($Height eq "6"))                  { $HLow = 2; }
	
	}
	return $HLow;	            		       
}


#this is a fonction to determine wheter the specis is a softwood or hardwood- used for further verification in species percentage determination
sub TypeForest {
	my $CurrentSpecies = shift(@_);
	my $GenusSpecies;

	$_ = $CurrentSpecies;
	tr/a-z/A-Z/;
	$CurrentSpecies = $_;

	if ($CurrentSpecies eq "")   { $GenusSpecies = MISSCODE; }
	elsif ($CurrentSpecies eq "GA")  { $GenusSpecies = "H"; }#H-Frax penn
	elsif ($CurrentSpecies eq "WS") { $GenusSpecies = "S"; }#S-Pice glau

	elsif ($CurrentSpecies eq "TA") { $GenusSpecies = "H"; }#H-Popu trem
	elsif ($CurrentSpecies eq "BS") { $GenusSpecies = "S"; }#S-Pice mari
	elsif ($CurrentSpecies eq "BP") { $GenusSpecies = "H"; }#H-Popu bals
	elsif ($CurrentSpecies eq "JP") { $GenusSpecies = "S"; }#S-Pinu bank
	elsif ($CurrentSpecies eq "WB") { $GenusSpecies = "H"; }#H-Betu papy
	elsif ($CurrentSpecies eq "BF") { $GenusSpecies = "S"; } #S-Abie bals
	elsif ($CurrentSpecies eq "WE") { $GenusSpecies = "H"; }#H-Ulmu amer
	elsif ($CurrentSpecies eq "TL") { $GenusSpecies = "S"; }#S-Lari lari
	elsif ($CurrentSpecies eq "LP") { $GenusSpecies = "S"; }#S-Pinu cont
	elsif ($CurrentSpecies eq "MM")  { $GenusSpecies = "H"; }#H-Frax penn
	elsif ($CurrentSpecies eq "BO") { $GenusSpecies = "H"; }#H-Quer macr
	return $GenusSpecies;
}



#Dertermine Latine name of species
sub Latine {
	my $CurrentSpecies = shift(@_);
	my $GenusSpecies;

	$_ = $CurrentSpecies;
	tr/a-z/A-Z/;
	$CurrentSpecies = $_;

	if ($CurrentSpecies eq "")   { $GenusSpecies = "XXXX MISS"; }

	elsif ($Species_table->{$CurrentSpecies}) { $GenusSpecies = $Species_table->{$CurrentSpecies}; }
	else 	 {$GenusSpecies = SPECIES_ERRCODE;  print SPECSLOGFILE "Illegal species code $CurrentSpecies,CAS_ID=$Glob_CASID,file=$Glob_filename\n";  } 
	return $GenusSpecies;
}


sub Latine_oldvers {
	my $CurrentSpecies = shift(@_);
	my $GenusSpecies;

	$_ = $CurrentSpecies;
	tr/a-z/A-Z/;
	$CurrentSpecies = $_;

	if ($CurrentSpecies eq "")   { $GenusSpecies = MISSCODE; }
	elsif ($CurrentSpecies eq "GA")  { $GenusSpecies = "Frax penn"; } 
	elsif ($CurrentSpecies eq "WS") { $GenusSpecies = "Pice glau"; } 
	elsif ($CurrentSpecies eq "TA") { $GenusSpecies = "Popu trem"; } 
	elsif ($CurrentSpecies eq "BS") { $GenusSpecies = "Pice mari"; } 
	elsif ($CurrentSpecies eq "BP") { $GenusSpecies = "Popu bals"; } 
	elsif ($CurrentSpecies eq "JP") { $GenusSpecies = "Pinu bank"; } 
	elsif ($CurrentSpecies eq "WB") { $GenusSpecies = "Betu papy"; } 
	elsif ($CurrentSpecies eq "BF") { $GenusSpecies = "Abie bals"; }  
	elsif ($CurrentSpecies eq "WE") { $GenusSpecies = "Ulmu amer"; } 
	elsif ($CurrentSpecies eq "TL") { $GenusSpecies = "Lari lari"; } 
	elsif ($CurrentSpecies eq "LP") { $GenusSpecies = "Pinu cont"; } 
	elsif ($CurrentSpecies eq "MM")  { $GenusSpecies = "Acer negu"; } 
	elsif ($CurrentSpecies eq "BO") { $GenusSpecies = "Quer macr"; } 
        else { print SPERRSFILE " error on $CurrentSpecies\n";  $GenusSpecies = ERRCODE; #$GenusSpecies = ERRCODE; #exit(-1); 
	}
	return $GenusSpecies;
}
#WS WHITE SPRUCE TA TREMBLING ASPEN BS BLACK SPRUCE BP  BLACK POPLAR JP JACK PINE WB WHITE BIRCH
#BF BALSAM FIRE WE WHITE ELM TL TAMARACK GA GREEN ASH LP[ LODGEPOLE PINE MM GREEN ASH BO BURR OAK 
#GR GRASSLAND   (R1 or R2) SB SCRUB BRUSH (R1 or R2)

#Determine Species from the 5 Species fields
sub Species_UTM{
	my $SpAssoc    = shift(@_);
	my $Sp1    = shift(@_);
	my $Sp1Per=0;
	my $Sp2    = shift(@_);
	my $Sp2Per=0;
	my $Sp3    = shift(@_);
	my $Sp3Per=0;
	my $Sp4    = shift(@_);
	my $Sp4Per=0;
	my $Sp5    = shift(@_);
	my $Sp5Per=0;
	my $spfreq=shift(@_);
	my $Species;
	my $CurrentSpec;
	my $nnsp1=0;my $nnsp2=0;my $notnull=0;

	if($Sp1 ne "" ){$nnsp1++;$notnull++;}
	if($Sp2 ne "" ){$nnsp1++;$notnull++;}
	if($Sp3 ne "" ){$nnsp1++;$notnull++;}
	if($Sp4 ne "" ){$nnsp2++;$notnull++;}
	if($Sp5 ne "" ){$nnsp2++;$notnull++;}

	if($SpAssoc eq "S" || $SpAssoc eq "H"){
		if($notnull==1)
			{
					$Sp1Per=100;$Sp2Per=0;$Sp3Per=0;$Sp4Per=0;$Sp5Per=0;
					if($Sp1 eq "" ){return "-11,"."$Sp1".","."$Sp2".","."$Sp3".","."$Sp4".","."$Sp5";}
			}
		elsif($notnull==2){  
					
					if($nnsp1==1 && $nnsp2==1){
									$Sp1Per=80;$Sp2Per=0;$Sp3Per=0;$Sp4Per=20;$Sp5Per=0;
									if($Sp1 eq "" || $Sp4 eq ""){
										return "#121,"."$Sp1".","."$Sp2".","."$Sp3".","."$Sp4".","."$Sp5";
									}
					}
					elsif($nnsp1==2 && (( $Sp1 ne "JP" &&    $Sp2 ne "BS") || ($Sp2 ne "BS" || $Sp2 ne "JP" )) ){		
									$Sp1Per=70;$Sp2Per=30;$Sp3Per=0;$Sp4Per=0;$Sp5Per=0;
									if($Sp1 eq "" || $Sp2 eq ""){
										return "#122,"."$Sp1".","."$Sp2".","."$Sp3".","."$Sp4".","."$Sp5";
									}
					}
					elsif($nnsp1==2 && ( $Sp1 eq "JP" || $Sp1 eq "BS")  &&  ($Sp2 eq "BS" || $Sp2 eq "JP" )){		
									$Sp1Per=60;$Sp2Per=40;$Sp3Per=0;$Sp4Per=0;$Sp5Per=0;
					}
					else {return "!!!!undefined config1";}
		}
		elsif($notnull==3){
					if($nnsp1==3){
							$Sp1Per=40;$Sp2Per=30;$Sp3Per=30;$Sp4Per=0;$Sp5Per=0;
							if($Sp1 eq "" || $Sp2 eq "" || $Sp3 eq ""){
							return "#131,"."$Sp1".","."$Sp2".","."$Sp3".","."$Sp4".","."$Sp5";}
					}
					elsif($nnsp1==2) {
							$Sp1Per=50;$Sp2Per=30;$Sp3Per=0;$Sp4Per=20;$Sp5Per=0;
							if($Sp1 eq "" || $Sp2 eq "" || $Sp4 eq ""){
							return "#132,"."$Sp1".","."$Sp2".","."$Sp3".","."$Sp4".","."$Sp5";}
					}
					elsif($nnsp1==1) {
							$Sp1Per=70;$Sp2Per=0;$Sp3Per=0;$Sp4Per=20;$Sp5Per=10;
							if($Sp1 eq "" || $Sp4 eq "" || $Sp5 eq ""){
							return "#133,"."$Sp1".","."$Sp2".","."$Sp3".","."$Sp4".","."$Sp5";}
					}
					else {return "!!!!undefined config2";}
		} 
		elsif($notnull==4){
					if($nnsp1==2){
							$Sp1Per=40;$Sp2Per=30;$Sp3Per=0;$Sp4Per=20;$Sp5Per=10;
							if($Sp1 eq "" || $Sp2 eq "" || $Sp4 eq ""|| $Sp5 eq ""){
							return "#141,"."$Sp1".","."$Sp2".","."$Sp3".","."$Sp4".","."$Sp5";}
					}
					elsif($nnsp1==3) {
								$Sp1Per=50;$Sp2Per=20;$Sp3Per=20;$Sp4Per=10;$Sp5Per=0;
								if($Sp1 eq "" || $Sp2 eq ""|| $Sp3 eq "" || $Sp4 eq ""){
									return "#142,"."$Sp1".","."$Sp2".","."$Sp3".","."$Sp4".","."$Sp5";}
					}
					else {return "!!!!undefined config3";}
		} 
		elsif($notnull==5){
					 
					$Sp1Per=40;$Sp2Per=20;$Sp3Per=20;$Sp4Per=10;$Sp5Per=10;
						if($Sp1 eq "" || $Sp2 eq "" ||$Sp3 eq "" || $Sp4 eq ""|| $Sp5 eq "")
						{
							return "#15,"."$Sp1".","."$Sp2".","."$Sp3".","."$Sp4".","."$Sp5";
						}
		}
	
	} 
	elsif($SpAssoc eq "SH" || $SpAssoc eq "HS"){
		
		if($notnull==2){  
					if($nnsp1==2){
							$Sp1Per=60;$Sp2Per=40;$Sp3Per=0;$Sp4Per=0;$Sp5Per=0;
							if($Sp1 eq "" || $Sp2 eq "" )
								{
									return "#22,"."$Sp1".","."$Sp2".","."$Sp3".","."$Sp4".","."$Sp5";
							}
					}
					elsif($nnsp1==1 && $nnsp2==1) {
							$Sp1Per=65;$Sp2Per=0;$Sp3Per=0;$Sp4Per=35;$Sp5Per=0;
							if($Sp1 eq "" || $Sp4 eq "" )
								{
									return "#23,"."$Sp1".","."$Sp2".","."$Sp3".","."$Sp4".","."$Sp5";
							}
					 # return "#this from BK ---SH  first 2 species are not primary "."$Sp1".","."$Sp2".","."$Sp3".","."$Sp4".","."$Sp5\n";
					}
					else {return "!!!!undefined config4";}
					
		}
		elsif($notnull==3){
					if($nnsp1==2 && $nnsp2==1) 
						{	
							if( TypeForest($Sp1) ne TypeForest($Sp2) &&  TypeForest($Sp2) eq TypeForest($Sp4))  
								{
									$Sp1Per=60;$Sp2Per=30;$Sp3Per=0;$Sp4Per=10;$Sp5Per=0;
								 }
							elsif( TypeForest($Sp1) ne TypeForest($Sp2) &&  TypeForest($Sp1) eq TypeForest($Sp4))  
								{
									$Sp1Per=40;$Sp2Per=40;$Sp3Per=0;$Sp4Per=20;$Sp5Per=0;
								 }
							elsif( TypeForest($Sp1) eq TypeForest($Sp2) &&  TypeForest($Sp1) ne TypeForest($Sp4))  
								{
									$Sp1Per=50;$Sp2Per=20;$Sp3Per=0;$Sp4Per=30;$Sp5Per=0;#verify with Steve
								 }
							else {return "!!!!undefined config5";}
							if($Sp1 eq "" || $Sp2 eq ""|| $Sp4 eq "" )
								{
									return "#24,"."$Sp1".","."$Sp2".","."$Sp3".","."$Sp4".","."$Sp5";
							}
					}
					elsif($nnsp1==1 && $nnsp2==2) {
							# print "my config1\n";
							if( TypeForest($Sp1) ne TypeForest($Sp4) &&  TypeForest($Sp4) eq TypeForest($Sp5))  
								{
									$Sp1Per=60;$Sp2Per=0;$Sp3Per=0;$Sp4Per=30;$Sp5Per=10;
								 }
							elsif( TypeForest($Sp1) ne TypeForest($Sp4) &&  TypeForest($Sp1) eq TypeForest($Sp5))  
								{
									$Sp1Per=40;$Sp2Per=0;$Sp3Per=0;$Sp4Per=40;$Sp5Per=20;
								 }
							else {return "!!!!undefined config6";}
							if($Sp1 eq "" || $Sp4 eq ""|| $Sp5 eq "" )
								{
									return "#24,"."$Sp1".","."$Sp2".","."$Sp3".","."$Sp4".","."$Sp5";
							}

					}
					else { 
							 print "my config2\n";
							if( TypeForest($Sp1) ne TypeForest($Sp2) &&  TypeForest($Sp2) eq TypeForest($Sp3))  
								{
									$Sp1Per=60;$Sp2Per=30;$Sp3Per=10;$Sp4Per=0;$Sp5Per=0;
								 }
							elsif( TypeForest($Sp1) ne TypeForest($Sp2) &&  TypeForest($Sp1) eq TypeForest($Sp3))  
								{
									$Sp1Per=40;$Sp2Per=40;$Sp3Per=20;$Sp4Per=0;$Sp5Per=0;
								 }
							else {return "!!!!undefined config7";}
					}
		} 
		elsif($notnull==4){
					if($nnsp1==2 && $nnsp2==2) 
						{   
							if( (TypeForest($Sp1) eq TypeForest($Sp4)) && ( TypeForest($Sp2) eq TypeForest($Sp5)) && ( TypeForest($Sp1) ne TypeForest($Sp2)) )  
							{
									$Sp1Per=30;$Sp2Per=30;$Sp3Per=0;$Sp4Per=20;$Sp5Per=20;
							}
							elsif( (TypeForest($Sp1) eq TypeForest($Sp4)) && ( TypeForest($Sp1) eq TypeForest($Sp5)) && ( TypeForest($Sp1) ne TypeForest($Sp2)) )  
								{
									$Sp1Per=40;$Sp2Per=30;$Sp3Per=0;$Sp4Per=20;$Sp5Per=10;
							}
							elsif( (TypeForest($Sp1) ne TypeForest($Sp2)) && ( TypeForest($Sp2) eq TypeForest($Sp4)) && ( TypeForest($Sp2) eq TypeForest($Sp5)) )  
								{
									$Sp1Per=50;$Sp2Per=30;$Sp3Per=0;$Sp4Per=10;$Sp5Per=10;
							}
							elsif( (TypeForest($Sp1) eq TypeForest($Sp2)) && ( TypeForest($Sp4) eq TypeForest($Sp5)) && ( TypeForest($Sp1) ne TypeForest($Sp4)) )  
								{
									$Sp1Per=30;$Sp2Per=20;$Sp3Per=0;$Sp4Per=30;$Sp5Per=20;#verif this with Steeve
							}
							elsif( (TypeForest($Sp1) ne TypeForest($Sp3)) && ( TypeForest($Sp3) eq TypeForest($Sp4)) && ( TypeForest($Sp4) eq TypeForest($Sp5)) )  
								{
									$Sp1Per=50;$Sp2Per=0;$Sp3Per=20;$Sp4Per=20;$Sp5Per=10;#verif this with Steeve
							}
							else {return "!!!!undefined config8";}

					}
					elsif($nnsp1==3 && $nnsp2==1) 
						{
							 #print "my config3\n";
							if( (TypeForest($Sp1) eq TypeForest($Sp3)) && ( TypeForest($Sp2) eq TypeForest($Sp4)) && ( TypeForest($Sp1) ne TypeForest($Sp2)) )  
							{
									$Sp1Per=30;$Sp2Per=30;$Sp3Per=20;$Sp4Per=20;$Sp5Per=0;
							}
							elsif( (TypeForest($Sp1) eq TypeForest($Sp3)) && ( TypeForest($Sp1) eq TypeForest($Sp4)) && ( TypeForest($Sp1) ne TypeForest($Sp2)) )  
								{
									$Sp1Per=40;$Sp2Per=30;$Sp3Per=20;$Sp4Per=10;$Sp5Per=0;
							}
							elsif( (TypeForest($Sp1) ne TypeForest($Sp2)) && ( TypeForest($Sp2) eq TypeForest($Sp3)) && ( TypeForest($Sp2) eq TypeForest($Sp4)) )  
								{
									$Sp1Per=50;$Sp2Per=30;$Sp3Per=10;$Sp4Per=10;$Sp5Per=0;
							}
							elsif( (TypeForest($Sp1) eq TypeForest($Sp2)) && ( TypeForest($Sp2) eq TypeForest($Sp3)) && ( TypeForest($Sp1) ne TypeForest($Sp4)) )  
								{
									$Sp1Per=40;$Sp2Per=20;$Sp3Per=10;$Sp4Per=30;$Sp5Per=0;#verif this with Steeve
							}
							else {return "!!!!undefined config9";}
						}
					else {return "!!!!undefined config10";}
		}
		elsif($notnull==5){
					if( (TypeForest($Sp1) ne TypeForest($Sp2)) && ( TypeForest($Sp1) eq TypeForest($Sp3)) && ( TypeForest($Sp1) eq TypeForest($Sp4)) && ( TypeForest($Sp1) eq TypeForest($Sp5)))  
							{
									$Sp1Per=30;$Sp2Per=30;$Sp3Per=20;$Sp4Per=10;$Sp5Per=10;
							}
							elsif( (TypeForest($Sp2) eq TypeForest($Sp5)) && ( TypeForest($Sp1) eq TypeForest($Sp3)) && ( TypeForest($Sp1) eq TypeForest($Sp4)) && ( TypeForest($Sp1) ne TypeForest($Sp2)))  
								{
									$Sp1Per=30;$Sp2Per=30;$Sp3Per=20;$Sp4Per=10;$Sp5Per=10;
							}
							elsif( (TypeForest($Sp1) eq TypeForest($Sp3)) && ( TypeForest($Sp2) eq TypeForest($Sp4)) && ( TypeForest($Sp2) eq TypeForest($Sp5)) && ( TypeForest($Sp1) ne TypeForest($Sp2)))  
								{
									$Sp1Per=30;$Sp2Per=30;$Sp3Per=20;$Sp4Per=10;$Sp5Per=10;
							}
elsif( (TypeForest($Sp1) ne TypeForest($Sp2)) && ( TypeForest($Sp2) eq TypeForest($Sp3)) && ( TypeForest($Sp2) eq TypeForest($Sp4)) && ( TypeForest($Sp2) eq TypeForest($Sp5)))  
								{
									$Sp1Per=40;$Sp2Per=30;$Sp3Per=10;$Sp4Per=10;$Sp5Per=10;
							}
elsif( (TypeForest($Sp1) eq TypeForest($Sp2)) && ( TypeForest($Sp2) eq TypeForest($Sp3)) && ( TypeForest($Sp4) eq TypeForest($Sp5)) && ( TypeForest($Sp1) ne TypeForest($Sp4)))  
								{
									$Sp1Per=30;$Sp2Per=20;$Sp3Per=10;$Sp4Per=30;$Sp5Per=10;#verif with steve
							}
					else {return "!!!!undefined config11";}
		}
	} 

$spfreq->{$Sp1}++;
$spfreq->{$Sp2}++;
$spfreq->{$Sp3}++;
$spfreq->{$Sp4}++;
$spfreq->{$Sp5}++;

	$Sp1 = Latine($Sp1); $Sp2 = Latine($Sp2); $Sp3 = Latine($Sp3); $Sp4 = Latine($Sp4); $Sp5 = Latine($Sp5);
	$Species = $Sp1 . "," . $Sp1Per . "," . $Sp2 . "," . $Sp2Per . "," . $Sp3 . "," . $Sp3Per . "," . $Sp4 . "," . $Sp4Per . "," . $Sp5 . "," . $Sp5Per;

	#$Species = $Sp1 . "," . $Sp1Per . "," . $Sp2 . "," . $sp2Per . "," . $Sp3 . "," . $sp3Per . "," . $Sp4 . "," . $sp4Per. "," . $Sp5 . "," . $sp5Per;

	return $Species;
}


#Determine Species from the 5 Species fields
sub Species_UTM_old{
	my $SpAssoc    = shift(@_);
	my $Sp1    = shift(@_);
	my $Sp1Per=0;
	my $Sp2    = shift(@_);
	my $Sp2Per=0;
	my $Sp3    = shift(@_);
	my $Sp3Per=0;
	my $Sp4    = shift(@_);
	my $Sp4Per=0;
	my $Sp5    = shift(@_);
	my $Sp5Per=0;
	my $Species;
	my $CurrentSpec;
	my $nnsp1=0;my $nnsp2=0;my $notnull=0;

	if($Sp1 ne "" ){$nnsp1++;$notnull++;}
	if($Sp2 ne "" ){$nnsp1++;$notnull++;}
	if($Sp3 ne "" ){$nnsp1++;$notnull++;}
	if($Sp4 ne "" ){$nnsp2++;$notnull++;}
	if($Sp5 ne "" ){$nnsp2++;$notnull++;}


	if($SpAssoc eq "S" || $SpAssoc eq "H"){
		if($notnull==1)
			{
					$Sp1Per=100;$Sp2Per=0;$Sp3Per=0;$Sp4Per=0;$Sp5Per=0;
			}
		elsif($notnull==2){  
					if(($Sp1 ne "JP" && $Sp2 ne "BS") && ($Sp2 ne "JP" && $Sp1 ne "BS"))
						{
							$Sp1Per=80;$Sp2Per=20;$Sp3Per=0;$Sp4Per=0;$Sp5Per=0;
					}
					else {$Sp1Per=60;$Sp2Per=40;$Sp3Per=0;$Sp4Per=0;$Sp5Per=0;}

					if($nnsp2 >0) {return "#1"."$SpAssoc ::: $Sp1, $Sp2, $Sp3, $Sp4, $Sp5";}
		}
		elsif($notnull==3){
					if(($Sp1 eq "JP" && $Sp2 eq "BS") || ($Sp2 eq "JP" && $Sp1 eq "BS"))
						{
							$Sp1Per=60;$Sp2Per=30;$Sp3Per=10;$Sp4Per=0;$Sp5Per=0;
					}
					else {$Sp1Per=70;$Sp2Per=20;$Sp3Per=10;$Sp4Per=0;$Sp5Per=0;}
					
					if($nnsp2 >0) {return  "#2"."$SpAssoc ::: $Sp1, $Sp2, $Sp3, $Sp4, $Sp5";}
		} 
		
	
	} 
	elsif($SpAssoc eq "SH" || $SpAssoc eq "HS"){
		
		if($notnull==2){  
					if($nnsp1==2) 
							{return "#3"."$SpAssoc ::: $Sp1, $Sp2, $Sp3, $Sp4, $Sp5";}
					elsif($nnsp1==1 && $nnsp2==1) {
							$Sp1Per=70;$Sp2Per=0;$Sp3Per=0;$Sp4Per=30;$Sp5Per=0;
					}
					
		}
		elsif($notnull==3){
					if($nnsp1==2 && $nnsp2==1) 
						{	
							if( TypeForest($Sp1) ne TypeForest($Sp2) && TypeForest($Sp2) eq TypeForest($Sp3))  
								{
									$Sp1Per=70;$Sp2Per=20;$Sp3Per=0;$Sp4Per=10;$Sp5Per=0;
								 }
							elsif( TypeForest($Sp1) eq TypeForest($Sp2) && TypeForest($Sp2) ne TypeForest($Sp3))  
								{
									$Sp1Per=50;$Sp2Per=20;$Sp3Per=0;$Sp4Per=30;$Sp5Per=0;
								 }

					}
					elsif($nnsp1==1 && $nnsp2==2) {
							 
							$Sp1Per=70;$Sp2Per=0;$Sp3Per=0;$Sp4Per=20;$Sp5Per=10;
					}
					else {return "#4"."$SpAssoc ::: $Sp1, $Sp2, $Sp3, $Sp4, $Sp5";}
		} 
		elsif($notnull==4){
					if($nnsp1==2 && $nnsp2==2) 
						{ 
							if( ($Sp1 ne "" && $Sp2 ne "") &&  (TypeForest($Sp1) eq TypeForest($Sp2)) && (TypeForest($Sp4)eq TypeForest($Sp5)) && (TypeForest($Sp1) ne TypeForest($Sp4)) ) {
							$Sp1Per=30;$Sp2Per=20;$Sp3Per=0;$Sp4Per=30;$Sp5Per=20;
							}
							elsif( (TypeForest($Sp1) ne TypeForest($Sp2)) || ($Sp3 ne "" && TypeForest($Sp1) ne TypeForest($Sp3))  )  
								{#print "BREAKING !!!! ERROR ON SPECIES PERCENTAGE (4) WITH $SpAssoc, $Sp1, $Sp2, $Sp3, $Sp4, $Sp5\n"; 
								if ($Sp3 ne "") {$Sp1Per=50;$Sp2Per=0;$Sp3Per=30;$Sp4Per=10;$Sp5Per=10;}
								elsif ($Sp2 ne "") {$Sp1Per=50;$Sp2Per=30;$Sp3Per=0;$Sp4Per=10;$Sp5Per=10;}
						}

					}
					elsif($nnsp1==3 && $nnsp2==1) 
						{
							$Sp1Per=40;$Sp2Per=20;$Sp3Per=10;$Sp4Per=30;$Sp5Per=0;
							if($Sp1 eq "" || $Sp2 eq "" ||$Sp3 eq "" ||$Sp4 eq ""){return "#6"."$Sp1, $Sp2, $Sp3, $Sp4, $Sp5";}
							#print "BREAKING !!!!ASK JOHN FOR THIS CONFIG 3-1 $SpAssoc,  $Sp1, $Sp2, $Sp3, $Sp4, $Sp5\n";  
						}
					else {return "#5"."$Sp1, $Sp2, $Sp3, $Sp4, $Sp5";}
		}
		elsif($notnull==5){
					if($nnsp1==3 && $nnsp2==2) 
						{ $Sp1Per=30;$Sp2Per=20;$Sp3Per=10;$Sp4Per=30;$Sp5Per=10;}
					else { return "#8"."$Sp1, $Sp2, $Sp3, $Sp4, $Sp5";}
		}
	} 

	$Sp1 = Latine($Sp1); $Sp2 = Latine($Sp2); $Sp3 = Latine($Sp3); $Sp4 = Latine($Sp4); $Sp5 = Latine($Sp5);
	$Species = $Sp1 . "," . $Sp1Per . "," . $Sp2 . "," . $Sp2Per . "," . $Sp3 . "," . $Sp3Per . "," . $Sp4 . "," . $Sp4Per . "," . $Sp5 . "," . $Sp5Per;

	#$Species = $Sp1 . "," . $Sp1Per . "," . $Sp2 . "," . $sp2Per . "," . $Sp3 . "," . $sp3Per . "," . $Sp4 . "," . $sp4Per. "," . $Sp5 . "," . $sp5Per;

	return $Species;
}


#Determine upper stand origin from Origin
sub UpperOrigin {
	my $Origin;
	my $firstdgt;
	($Origin) = shift(@_);


	if ($Origin > 0) {

			if ($INV_version eq "UTM") {
							$firstdgt=substr $Origin, 0, 1 ;
							if ($firstdgt == 8 ||$firstdgt==9 ) { 
											$Origin = $Origin+100;
 	 			 							$Origin = $Origin*10;
											$Origin = $Origin + 5;
							}
	      						elsif ($firstdgt == 1) {$Origin = $Origin + 5; }
	     						else {$Origin = ERRCODE;}
			}
			elsif ($INV_version eq "SFVI") {

							  if (($Origin % 10) > 0) { $Origin = $Origin; }
							  else  { $Origin = $Origin + 5; }
			}	
			
	}
	else { $Origin = ERRCODE; }

	return $Origin;
}

#Determine lower stand origin from Origin
sub LowerOrigin {
	my $Origin;
	my $firstdgt;
	($Origin) = shift(@_);


	if ($Origin > 0) {

		if ($INV_version eq "UTM") {
							$firstdgt=substr $Origin, 0, 1 ;
							if ($firstdgt == 8 ||$firstdgt==9 ) { 
												$Origin = $Origin+100;
 	 			 								$Origin = $Origin*10;
												$Origin = $Origin -4;
							}
	       						elsif ($firstdgt == 1) {$Origin = $Origin -4 ;  }
	      						else {$Origin = ERRCODE;}
		}
		elsif ($INV_version eq "SFVI") {
	 						 if (($Origin % 10) > 0) { $Origin = $Origin; }
	 						 else  { $Origin = $Origin-4; }
		}

	}
	else { $Origin = ERRCODE; }

	return $Origin;
}



#UnProdForest TM,TR, ?OM, AL, SD, SC, NP, 
sub UnprodForested {
	my $UnprodFor;
	my %UnprodForList = ("0", 1, "3100", 1, "3200", 1, "3900", 1   );


	($UnprodFor) = shift(@_);
	if ($UnprodForList {$UnprodFor} ) { } else { $UnprodFor = ERRCODE; }

	if($INV_version eq "UTM"){
					if  ($UnprodFor eq "0" )	{ $UnprodFor = MISSCODE; }
					elsif (($UnprodFor eq "3100"))	{ $UnprodFor = "TM"; }
					elsif (($UnprodFor  eq "3200"))	{ $UnprodFor  = "TR"; }
					elsif (($UnprodFor eq "3900"))	{$UnprodFor = "SD"; }  ##moved from other type
					else { $UnprodFor = ERRCODE; }
	}
	elsif($INV_version eq "SFVI")	{$UnprodFor = MISSCODE;}
	return $UnprodFor;
}


#Determine Naturally non-vegetated stands from NP
#Natnonveg ==== AP, LA, RI, OC, RK, SD, SI, SL, EX, BE, WS, FL, IS, TF

sub NaturallyNonVegetated{
	my $NatNonVeg;
	my %NatNonVegList = ("0", 1, "3800", 1, "5100", 1, "3400", 1, "5210", 1, "5220", 1, "5200", 1 );

	($NatNonVeg) = shift(@_);
	if ($NatNonVegList {$NatNonVeg} ) { } else { $NatNonVeg = ERRCODE; }

	if($INV_version eq "UTM"){
					if  ($NatNonVeg eq "0")	{ $NatNonVeg = MISSCODE; }
					elsif (($NatNonVeg eq "3800"))	{ $NatNonVeg = "SD"; }
					#elsif (($NatNonVeg eq "3700"))	{ $NatNonVeg = "OT"; }
					elsif (($NatNonVeg eq "5100"))	{ $NatNonVeg = "FL"; }
					elsif (($NatNonVeg eq "3400"))	{ $NatNonVeg = "RK"; }
					elsif (($NatNonVeg eq "5210"))	{ $NatNonVeg = "LA"; }
					elsif (($NatNonVeg eq "5200"))	{ $NatNonVeg = "FL"; }
					elsif (($NatNonVeg eq "5220"))	{ $NatNonVeg = "RI"; }
					else { $NatNonVeg = ERRCODE; }
	}
	elsif($INV_version eq "SFVI"){
					if  ($NatNonVeg eq "")					{ $NatNonVeg = MISSCODE; }
					#elsif (($NatNonVeg eq "UK"))	{ $NatNonVeg = "OT"; }
					elsif (($NatNonVeg eq "CB"))	{ $NatNonVeg = "EX"; }
					elsif (($NatNonVeg eq "RK"))	{ $NatNonVeg = "RK"; }
					#elsif (($NatNonVeg eq "SA"))	{ $NatNonVeg = "SA"; }#ask John for SA value
					elsif (($NatNonVeg eq "MS"))	{ $NatNonVeg = "EX"; }
					elsif (($NatNonVeg eq "GR"))	{ $NatNonVeg = "WS"; }
					elsif (($NatNonVeg eq "SB"))	{ $NatNonVeg = "WS"; }
					elsif (($NatNonVeg eq "WA"))	{ $NatNonVeg = "LA"; }
					elsif (($NatNonVeg eq "LA"))	{ $NatNonVeg = "LA"; }
					elsif (($NatNonVeg eq "RI"))	{ $NatNonVeg = "RI"; }
					elsif (($NatNonVeg eq "FL"))	{ $NatNonVeg = "FL"; }
					elsif (($NatNonVeg eq "SL"))	{ $NatNonVeg = "FL"; }
					#elsif (($NatNonVeg eq "FP"))	{ $NatNonVeg = "BP"; }
					elsif (($NatNonVeg eq "ST"))	{ $NatNonVeg = "RI"; }
					else { $NatNonVeg = ERRCODE; }
	}
	return $NatNonVeg;
}

#3100  TREED MUSKEG  Treed Muskeg= TM	  3200  TREED ROCK  Treed Rock=TR #3800  SAND  Sand=SD  3400  CLEAR ROCK Clear Rock=RK	3700  CLEARING  Clearing =OT  5100  FLOODED LAND  Flooded=FL  5210  WATER-LAKE SURFACE  Lake=LA	 5220  WATER-RIVER SURFACE   Large Stream=RI #3300  CLEAR MUSKEG  Clear Muskeg=OM  3500  BRUSHLAND  Brushland=ST 3600  MEADOW  Meadow=HG  3900  NON PRODUCTIVE BURN-OVER  Non Productive Burn=SD 4000  PASTURE LAND  Pasture or Cropland = CL  #5200  WATER-UNKNOWN SURFACE 	#9000  NOT TYPED	
									
#NonForestedVeg ---ST, SL, HF, HE, HG, BR, OM, BT
#Determine Non-forested vegetation stands  from NP
sub NonForested{
	my $NonForVeg = shift(@_);
	my $NonForVegHgt = shift(@_);
	my %NonForVegList = ("0", 1, "3300", 1, "3500", 1, "3600", 1, "TS", 1, "LS", 1, "NE", 1, "FE", 1, "GR", 1, "MO", 1, "LI", 1, "AV", 1);

	if ($NonForVegList {$NonForVeg} ) { } else { $NonForVeg = ERRCODE; }

	if($INV_version eq "UTM"){
					if  ($NonForVeg eq "0")		{ $NonForVeg =MISSCODE; }
					elsif (($NonForVeg eq "3300"))	{ $NonForVeg = "OM"; }
					elsif (($NonForVeg eq "3500"))	{ $NonForVeg = "ST"; }
					elsif (($NonForVeg eq "3600"))	{ $NonForVeg = "HG"; }
					#elsif (($NonForVeg eq "3900"))	{ $NonForVeg = "SD"; }
					#elsif (($NonForVeg eq "4000"))	{ $NonForVeg = "CL"; }
					#elsif (($NonForVeg eq "9000"))	{ $NonForVeg = "OT"; }
					else { $NonForVeg = ERRCODE; }
	} 
	elsif($INV_version eq "SFVI"){
					if  ($NonForVeg eq "")		{ $NonForVeg =MISSCODE; }
					elsif (($NonForVeg eq "TS"))	{ $NonForVeg = "ST"; }#TS turn into ST
					elsif (($NonForVeg eq "LS"))	{ $NonForVeg = "SL"; }#LS turn into SL
					elsif (($NonForVeg eq "NE"))	{ $NonForVeg = "NE"; }#ask John is it HE?
					elsif (($NonForVeg eq "FE"))	{ $NonForVeg = "NF"; }#ask John is it HF?
					elsif (($NonForVeg eq "GR"))	{ $NonForVeg = "HG"; }
					elsif (($NonForVeg eq "MO"))	{ $NonForVeg = "BR"; }
					elsif (($NonForVeg eq "LI"))	{ $NonForVeg = "BR"; }
					elsif (($NonForVeg eq "AV"))	{ $NonForVeg = "HF"; }
					else { $NonForVeg = ERRCODE; }
	}
	return $NonForVeg;
}


#Anthropogenic IN, FA, CL, SE, LG, BP, OT
#Determine Naturally non-vegetated stands
sub NonVegetatedAnth{
	my $NatNonVeg;
	my %NatNonVegList = ("", 1, "ALA", 1, "AFS", 1, "POP", 1, "CEM", 1, "REC", 1, "PEX", 1, "TAR", 1, "GPI", 1, "RWC", 1, "BPI", 1, "RRC", 1, "MIS", 1, "TIC", 1, "ASA", 1,  "PLC", 1, "NSA", 1, "MPC", 1, "OIS", 1, "OUS", 1, "3700", 1, "9000", 1, "4000", 1, "UK", 1, "FP", 1);

	($NatNonVeg) = shift(@_);
	if ($NatNonVegList {$NatNonVeg} ) { } else { $NatNonVeg = ERRCODE; }


	if($INV_version eq "UTM"){
					if (($NatNonVeg eq "3700"))	{ $NatNonVeg = "OT"; }			
					elsif (($NatNonVeg eq "9000"))	{ $NatNonVeg = "OT"; }
					elsif (($NatNonVeg eq "4000"))	{ $NatNonVeg = "CL"; }
					else { $NatNonVeg = ERRCODE; }
	}
	elsif($INV_version eq "SFVI"){
					if  ($NatNonVeg eq "")	{ $NatNonVeg = MISSCODE; }
					elsif (($NatNonVeg eq "ALA"))	{ $NatNonVeg = "CL"; }
					elsif (($NatNonVeg eq "AFS"))	{ $NatNonVeg = "FA"; }
					elsif (($NatNonVeg eq "POP"))	{ $NatNonVeg = "SE"; }
					elsif (($NatNonVeg eq "CEM"))	{ $NatNonVeg = "SE"; }
					elsif (($NatNonVeg eq "REC"))	{ $NatNonVeg = "FA"; }
					elsif (($NatNonVeg eq "WEN"))	{ $NatNonVeg = "FA"; }
					elsif (($NatNonVeg eq "PEX"))	{ $NatNonVeg = "IN"; }
					elsif (($NatNonVeg eq "TAR"))	{ $NatNonVeg = "FA"; }
					elsif (($NatNonVeg eq "GPI"))	{ $NatNonVeg = "IN"; }
					elsif (($NatNonVeg eq "RWC"))	{ $NatNonVeg = "FA"; }
					elsif (($NatNonVeg eq "BPI"))	{ $NatNonVeg = "BP"; }
					elsif (($NatNonVeg eq "RRC"))	{ $NatNonVeg = "FA"; }
					elsif (($NatNonVeg eq "MIS"))	{ $NatNonVeg = "IN"; }
					elsif (($NatNonVeg eq "TIC"))	{ $NatNonVeg = "FA"; }
					elsif (($NatNonVeg eq "ASA"))	{ $NatNonVeg = "IN"; }
					elsif (($NatNonVeg eq "PLC"))	{ $NatNonVeg = "FA"; }
					elsif (($NatNonVeg eq "NSA"))	{ $NatNonVeg = "IN"; }
					elsif (($NatNonVeg eq "MPC"))	{ $NatNonVeg = "FA"; }
					elsif (($NatNonVeg eq "OIS"))	{ $NatNonVeg = "IN"; }
					elsif (($NatNonVeg eq "OUS"))	{ $NatNonVeg = "IN"; }
					elsif (($NatNonVeg eq "UK"))	{ $NatNonVeg = "OT"; }#moved from other type
					elsif (($NatNonVeg eq "FP"))	{ $NatNonVeg = "BP"; }#moved from other type
					else { $NatNonVeg = ERRCODE; }
	}
	return $NatNonVeg;
}


#Determine Disturbance from Modifiers
sub Disturbancepreviuous {
	my $Mod;
	my $ModYr;
	my $Disturbance;

	($Mod) = shift(@_);
	($ModYr) = shift(@_);

	if ($Mod ne "") { $Disturbance = $Mod . "," . $ModYr; }
	else { $Disturbance = MISSCODE.",-1111"; }

	return $Disturbance;
}


#CO=CO	BO=BU	SCO=CO	WCO=CO

sub Disturbance{
	my $ModCode;
	my $ModYr;
	my $Extent="-8888,-8888";
	my $Mod;	
	my $Disturbance;
	
	my %ModList = ("", 1, "CO", 1, "BO", 1, "SCO", 1, "WCO", 1, "OCO", 1, "OPC", 1, "WPC", 1, "SPC", 1, "WI", 1, "HA", 1, "IN", 1, "DI", 1, "AK", 1, "SL", 1,
				"co", 1, "bo", 1, "sco", 1, "wco", 1,  "wi", 1, "ha", 1, "in", 1, "di", 1, "ak", 1, "sl", 1);
   
	($ModCode) = shift(@_);
	($ModYr) = shift(@_);
	if ($ModYr eq "" ) {$ModYr=MISSCODE; }

	if ($ModList{$ModCode} ) { 

	if ($ModCode ne "") { 
 				if (($ModCode  eq "CO") || ($ModCode eq "co")) { $Mod="CO"; }
				elsif (($ModCode  eq "BO") || ($ModCode eq "bo")) { $Mod="BU"; }

				elsif($INV_version eq "UTM"){
								if (($ModCode  eq "SCO") || ($ModCode eq "sco")) { $Mod="CO"; }
								elsif (($ModCode  eq "WCO") || ($ModCode eq "wco")) { $Mod="CO"; }
								elsif (($ModCode  eq "WPC") || ($ModCode eq "SPC")|| ($ModCode eq "OPC")) { $Mod="CO"; $Extent="30,70";}
								elsif (($ModCode  eq "OCO") ) { $Mod="CO"; }
								else { $Mod = ERRCODE; }	
				}
				elsif($INV_version eq "SFVI"){
								if (($ModCode  eq "WI") || ($ModCode eq "wi")) { $Mod="WF"; }
								elsif (($ModCode  eq "HA") || ($ModCode eq "ha")) { $Mod="WE"; }
								elsif (($ModCode  eq "IN") || ($ModCode eq "in")) { $Mod="IK"; }
								elsif (($ModCode  eq "DI") || ($ModCode eq "di")) { $Mod="DI"; }
								elsif (($ModCode  eq "AK") || ($ModCode eq "ak")) { $Mod="OT"; }
								elsif (($ModCode  eq "SL") || ($ModCode eq "sl")) { $Mod="SL"; }
								else { $Mod = ERRCODE; }
				}
				$Disturbance = $Mod . "," . $ModYr. "," . $Extent; 
	                  }
	   else { $Disturbance = MISSCODE.",-1111". "," . $Extent; }
	} else { $Mod = ERRCODE; $Disturbance = $Mod . "," . $ModYr. "," . $Extent;  }

	return $Disturbance;
}



#1-25	26-50	51-75	76-95	96-100	

sub DisturbanceExtUpper {
    	my $ModExt;
        my $DistExtUpper;

	my %ModExtList = ("", 1, "1", 1, "2", 1, "3", 1, "4", 1, "5", 1);
	 
	($ModExt) = shift(@_);
	if ($ModExtList {$ModExt} ) { } else { $DistExtUpper = ERRCODE; }

	
	if($INV_version eq "UTM")	{$DistExtUpper = MISSCODE; }
	elsif($INV_version eq "SFVI"){
					if  ($ModExt eq "")                    {$DistExtUpper = MISSCODE; }
					elsif (($ModExt eq "1"))  	       { $DistExtUpper = 25; }
					elsif (($ModExt eq "2"))                  { $DistExtUpper = 50; }
					elsif (($ModExt eq "3"))                  { $DistExtUpper = 75; }
					elsif (($ModExt eq "4"))                  { $DistExtUpper = 95; }
					elsif (($ModExt eq "5"))                  { $DistExtUpper = 100; }
	}
        return $DistExtUpper;
}

sub DisturbanceExtLower {
       	my $ModExt;
        my $DistExtLower;

       my %ModExtList = ("", 1, "1", 1, "2", 1, "3", 1, "4", 1, "5", 1);
	 
	($ModExt) = shift(@_);
	if ($ModExtList {$ModExt} ) { } else { $DistExtLower = ERRCODE; }

	if($INV_version eq "UTM")	{$DistExtLower = MISSCODE; }
	elsif($INV_version eq "SFVI"){
					if  ($ModExt eq "")                    {$DistExtLower = MISSCODE; }
					elsif (($ModExt eq "1"))  	       { $DistExtLower = 1; }
					elsif (($ModExt eq "2"))                  { $DistExtLower = 26; }
					elsif (($ModExt eq "3"))                  { $DistExtLower = 51; }
					elsif (($ModExt eq "4"))                  { $DistExtLower = 76; }
					elsif (($ModExt eq "5"))                  { $DistExtLower = 96; }	
	}
       return $DistExtLower;
}


# Determine wetland codes
sub WetlandCodes_UTM {
	my $Drain = shift(@_);
	my $SoilT =  shift(@_);
	my $CrownClosure = shift(@_);
	my $NonProd = shift(@_);
	my $Spec1 = shift(@_);
	my $Spec2 = shift(@_);
	my $Spec1Per = shift(@_);
	
	#my $Spec3 = shift(@_);
	#my $Spec4 = shift(@_);
	#my $Spec5 = shift(@_);
	

	my $WetlandCode = "";
	
	$_ =$Drain ; tr/a-z/A-Z/; $Drain  = $_;
	$_ = $SoilT; tr/a-z/A-Z/; $SoilT = $_;
	$_ = $CrownClosure; tr/a-z/A-Z/; $CrownClosure = $_;
	$_ =$NonProd;tr/a-z/A-Z/; $NonProd = $_;
	$_ = $Spec1; tr/a-z/A-Z/; $Spec1 = $_;
	$_ = $Spec2; tr/a-z/A-Z/; $Spec2 = $_;
	if ( $Spec1Per eq "") { $Spec1Per = 0; }
	 
	
	
	if (($Drain  eq "PVP" || $SoilT eq "O") || ($Drain  eq "PD" && $SoilT eq "O")) { 

		  if (($Spec1 eq "BS") && ($Spec1Per == 100)  && (($CrownClosure eq "C") ||  ($CrownClosure eq "D") ) ) 
	  		  { $WetlandCode = "S,T,N,N,"; }
	  	  elsif (($Spec1 eq "BS") && ($Spec1Per == 100)  && (($CrownClosure eq "A") ||  ($CrownClosure eq "B") ) ) 
	  		  { $WetlandCode = "B,T,N,N,"; }
		  elsif ( (($Spec1 eq "BS") || ($Spec1 eq "TL") || ($Spec1 eq "WB") || ($Spec1 eq "MM"))  && (($Spec2 eq "BS") || ($Spec2 eq "TL") || ($Spec2 eq "WB") || ($Spec2 eq "MM")) ) 
	  		  { $WetlandCode = "S,T,N,N,"; }

	}
	elsif($NonProd == 3100 )  
	    { $WetlandCode = "W,T,-,-,"; }
	 elsif($NonProd == 3300 )  
	    { $WetlandCode = "W,O,-,-,"; }
	elsif($NonProd == 3500 )  
	    { $WetlandCode = "S,O,N,S,"; }
	elsif($NonProd == 3600 )  
	    { $WetlandCode = "M,O,N,G,"; }
	elsif($NonProd == 5100 )  
	    { $WetlandCode = "M,O,N,G,"; }

#else  { $WetlandCode = ERRCODE; }
	 if ($WetlandCode eq "") {$WetlandCode = MISSCODE;}# MISSCODE.",".MISSCODE.",".MISSCODE.",".MISSCODE.",";
	return $WetlandCode;
	
	
}

sub WetlandCodes_SFVI {
	my $Moist = shift(@_);
	my $SoilT =  shift(@_);
	my $CrownClosure = shift(@_);
	my $Height = shift(@_);
	my $NonFor = shift(@_);
	my $Spec1 = shift(@_);
	my $Spec2 = shift(@_);
	my $Spec1Per = shift(@_);
	
	#my $Spec3 = shift(@_);
	#my $Spec4 = shift(@_);
	#my $Spec5 = shift(@_);
	

	my $WetlandCode = "";
	
	$_ =$Moist ; tr/a-z/A-Z/; $Moist  = $_;
	$_ = $Height; tr/a-z/A-Z/; $Height = $_;
	$_ = $CrownClosure; tr/a-z/A-Z/; $CrownClosure = $_;
	$_ =$NonFor;tr/a-z/A-Z/; $NonFor = $_;
	$_ = $Spec1; tr/a-z/A-Z/; $Spec1 = $_;
	$_ = $Spec2; tr/a-z/A-Z/; $Spec2 = $_;
	if ( $Spec1Per eq "") { $Spec1Per = 0; }
	 
	
	
	if ($Moist  eq "MW") { 

		  if (($Spec1 eq "BS") && ($Spec1Per == 100)  && ($CrownClosure <= 50) &&  ($Height <12)  ) 
	  		  { $WetlandCode = "B,T,N,N,"; }
	  	  elsif (($Spec1 eq "BS") && ($Spec1Per == 100)  && ($CrownClosure <= 50) &&  ($Height >=12)  ) 
	  		  { $WetlandCode = "S,T,N,N,"; }
		  elsif (($Spec1 ne "")) 
	  		  { $WetlandCode = "S,T,N,N,"; }
	       	  elsif (($Spec1 ne "")  && ($CrownClosure >= 70)  ) 
	  		  { $WetlandCode = "S,T,N,N,"; }  		  

	}
	elsif ($Moist  eq "W") 
	    { 
 		  if (($Spec1 eq "BS") && ($Spec1Per == 100)  && ($CrownClosure <= 50) &&  ($Height <12)  ) 
	  		  { $WetlandCode = "B,T,N,N,"; }
	  	  elsif (($Spec1 eq "BS") && ($Spec1Per == 100)  && ($CrownClosure <= 50) &&  ($Height >=12)  ) 
	  		  { $WetlandCode = "S,T,N,N,"; }
		  elsif (($Spec1 eq "BS") && ($Spec1Per == 100)  && ($CrownClosure > 50) && ($CrownClosure < 70) &&  ($Height >=12)  ) 
	  		  { $WetlandCode = "S,T,N,N,"; }
		  elsif (($Spec1 eq "BS") && ($Spec1Per == 100)  && ($CrownClosure >= 70) &&  ($Height >=12)  ) 
	  		  { $WetlandCode = "S,F,N,N,"; }  	
	}
	 elsif($Moist  eq "VW") 
	    {
		  if ( (($Spec1 eq "BS") || ($Spec1 eq "TL") || ($Spec1 eq "WB") || ($Spec1 eq "MM") || ($Spec1 eq "BP"))  && (($Spec2 eq "BS") || ($Spec2 eq "TL") || 					($Spec2 eq "WB") || ($Spec2 eq "MM") || ($Spec2 eq "BP")) &&  ($CrownClosure >= 50) && ($CrownClosure < 70) &&  ($Height >=12)) 
 			{ $WetlandCode = "S,T,N,N,"; }
		  elsif ( (($Spec1 eq "BS") || ($Spec1 eq "TL") || ($Spec1 eq "WB") || ($Spec1 eq "MM") || ($Spec1 eq "BP"))  && (($Spec2 eq "BS") || ($Spec2 eq "TL") 					|| ($Spec2 eq "WB") || ($Spec2 eq "MM") || ($Spec2 eq "BP")) &&  ($CrownClosure >= 70) ) 
 			{ $WetlandCode = "S,F,N,N,"; }
 		  elsif ( (($Spec1 eq "BS") || ($Spec1 eq "TL"))  && (($Spec2 eq "BS") || ($Spec2 eq "TL") ) &&  ($CrownClosure < 50) &&  ($Height <12)) 
 			{ $WetlandCode = "F,T,N,N,"; }
		  elsif (($Spec1 eq "TL") && ($Spec1Per == 100)  && ($CrownClosure > 50) && ($CrownClosure < 70) &&  ($Height >=12)  ) 
	  		  { $WetlandCode = "S,T,N,N,"; }  	
 		  elsif (($Spec1 eq "TL") && ($Spec1Per == 100)  && ($CrownClosure >=70) ) 
	  		  { $WetlandCode = "S,F,N,N,"; }  	
 		  elsif (($Spec1 eq "TL") && ($Spec1Per == 100)  && ($CrownClosure <=50) ) 
	  		  { $WetlandCode = "F,T,N,N,"; }  	
		  elsif ((($Spec1 eq "GA") || ($Spec1 eq "WE") || ($Spec1 eq "WB") || ($Spec1 eq "MM")) && ($Spec1Per == 100)  && ($CrownClosure < 70) ) 
	  		  { $WetlandCode = "S,T,N,N,"; }
		  elsif ((($Spec1 eq "GA") || ($Spec1 eq "WE") || ($Spec1 eq "WB") || ($Spec1 eq "MM")) && ($Spec1Per == 100)  && ($CrownClosure >= 70) ) 
	  		  { $WetlandCode = "S,F,N,N,"; }  	  	

	}
	
	if ($Moist  eq "MW" || $Moist  eq "W" || $Moist  eq "VW") {

		if ($NonFor eq "HE" || $NonFor eq "GR")  { $WetlandCode = "M,O,N,G,"; }  
		elsif ($NonFor eq "MO")  { $WetlandCode = "F,O,N,N,"; }  
		elsif ($NonFor eq "AV")  { $WetlandCode = "O,O,N,N,"; }  
		elsif ($NonFor eq "TS" || $NonFor eq "LS")  { $WetlandCode = "S,O,N,S,"; }  
 	}

	 if ($WetlandCode eq "") {$WetlandCode = MISSCODE;}  # MISSCODE.",".MISSCODE.",".MISSCODE.",".MISSCODE.",";
	return $WetlandCode;
	
	
}



sub SKinv_to_CAS {
	my $SK_File = shift(@_);
	$Species_table = shift(@_);
	my $CAS_File = shift(@_);
	my $ERRFILE = shift(@_);
	my $nbiters = shift(@_);
	my $optgroups= shift(@_);
	my $pathname=shift(@_);
	my $TotalIT=shift(@_);
	my $SPERRS = shift(@_);
	#my $iters_fmu=shift(@_);
	#my $INFOHDR_File=shift(@_);

	my $temp=shift(@_);

 	my $spfreq=shift(@_);

	my $ncas=shift(@_);
	my $nlyr=shift(@_);
	my $nnfl=shift(@_);
	my $ndst=shift(@_);
	my $neco=shift(@_);
	my $ndstonly=shift(@_);
	my $necoonly=shift(@_);
	my $SPECSLOG=shift(@_);

	my  $ncasprev=0;
	my $nlyrprev=0;
	my  $nnflprev=0;
	my  $ndstprev=0;
	my  $necoprev=0;
	my $ndstonlyprev=0;
	my $necoonlyprev=0;

	my $CAS_File_HDR = $CAS_File . ".hdr";
	my $CAS_File_CAS = $CAS_File . ".cas";
	my $CAS_File_LYR = $CAS_File . ".lyr";
	my $CAS_File_NFL = $CAS_File . ".nfl";
	my $CAS_File_DST = $CAS_File . ".dst";
	my $CAS_File_ECO = $CAS_File . ".eco";

	$INV_version=$temp;  print "version $INV_version $CAS_File\n";
  
	#open (SKinv, "<$SK_File") || die "\n Error: Could not open input file $SK_File!\n";
	open (ERRS, ">>$ERRFILE") || die "\n Error: Could not open $ERRFILE file!\n";
	open (SPERRSFILE, ">>$SPERRS") || die "\n Error: Could not open $SPERRS file!\n";
	open (SPECSLOGFILE, ">>$SPECSLOG") || die "\n Error: Could not open $SPECSLOG file!\n";
	
	if($optgroups==1){

	 	$CAS_File_HDR = $pathname."/SKtable.hdr";
	 	$CAS_File_CAS = $pathname."/SKtable.cas";
	 	$CAS_File_LYR = $pathname."/SKtable.lyr";
	 	$CAS_File_NFL = $pathname."/SKtable.nfl";
	 	$CAS_File_DST = $pathname."/SKtable.dst";
	 	$CAS_File_ECO = $pathname."/SKtable.eco";
	}
	elsif($optgroups==2){

	 	$CAS_File_HDR = $pathname."/CanadaInventorytable.hdr";
	 	$CAS_File_CAS = $pathname."/CanadaInventorytable.cas";
	 	$CAS_File_LYR = $pathname."/CanadaInventorytable.lyr";
	 	$CAS_File_NFL = $pathname."/CanadaInventorytable.nfl";
	 	$CAS_File_DST = $pathname."/CanadaInventorytable.dst";
	 	$CAS_File_ECO = $pathname."/CanadaInventorytable.eco";
	}

	if(($optgroups==0) || ($optgroups==1 && $nbiters==1)|| ($optgroups==2 && $TotalIT==1)){

		open (CASHDR, ">$CAS_File_HDR") || die "\n Error: Could not open CAS header output file!\n";
		open (CASCAS, ">$CAS_File_CAS") || die "\n Error: Could not open CAS common attribute schema  file!\n";
		open (CASLYR, ">$CAS_File_LYR") || die "\n Error: Could not open CAS layer output file!\n";
		open (CASNFL, ">$CAS_File_NFL") || die "\n Error: Could not open CAS non-forested land output file!\n";
		open (CASDST, ">$CAS_File_DST") || die "\n Error: Could not open CAS disturbance output file!\n";
		open (CASECO, ">$CAS_File_ECO") || die "\n Error: Could not open CAS ecological output file!\n";
		#open (INFOHDR, "<$INFOHDR_File") || die "\n Error: Could not open file $INFOHDR_File !\n";
	
	
	print CASCAS "CAS_ID,ORIG_STAND_ID,STAND_STRUCTURE,NUM_OF_LAYERS,IDENTIFICATION_ID,MAP_SHEET_ID,GIS_AREA,GIS_PERIMETER,INVENTORY_AREA,PHOTO_YEAR\n";
print CASLYR "CAS_ID,SOIL_MOIST_REG,STRUCTURE_PER,LAYER,LAYER_RANK,CROWN_CLOSURE_UPPER,CROWN_CLOSURE_LOWER,HEIGHT_UPPER,HEIGHT_LOWER,PRODUCTIVE_FOR,SPECIES_1,SPECIES_PER_1,SPECIES_2,SPECIES_PER_2,SPECIES_3,SPECIES_PER_3,SPECIES_4,SPECIES_PER_4,SPECIES_5,SPECIES_PER_5,SPECIES_6,SPECIES_PER_6,SPECIES_7,SPECIES_PER_7,SPECIES_8,SPECIES_PER_8,SPECIES_9,SPECIES_PER_9,SPECIES_10,SPECIES_PER_10,ORIGIN_UPPER,ORIGIN_LOWER,SITE_CLASS,SITE_INDEX\n";

	print CASNFL "CAS_ID,SOIL_MOIST_REG,STAND_STRUCTURE,STRUCTURE_PER,NUM_OF_LAYERS,LAYER,LAYER_RANK,CROWN_CLOSURE_UPPER,CROWN_CLOSURE_LOWER,HEIGHT_UPPER,HEIGHT_LOWER,NAT_NON_VEG,NON_FOR_ANTH,NON_FOR_VEG\n";
	print CASDST "CAS_ID,DIST_1,DIST_YR_1,DIST_EXT_UPPER_1,DIST_EXT_LOWER_1,DIST_2,DIST_YR_2,DIST_EXT_UPPER_2,DIST_EXT_LOWER_2,DIST_3,DIST_YR_3,DIST_EXT_UPPER_3,DIST_EXT_LOWER_3,LAYER\n";
	print CASECO "CAS_ID,WETLAND_TYPE,WET_VEG_COVER,WET_LANDFORM_MOD,WET_LOCAL_MOD,ECO_SITE\n";

	
	# ===== Output to header file =====
#"IDENTIFICATION_ID,JURISDICTION,COORDINATE_SYS,PROJECTION,DATUM,INVENTORY_OWNER,LAND_OWNER,PERMISSION,TENURE_TYPE,INV_TYPE,INV_VERSION,INV_START_YR,INV_FINISH_YR,INV_ACQ_ID,INV_ACQ_YR,INV_UPDATE_YR\n";
	print CASHDR 
"HEADER_ID,JURISDICTION,COORD_SYS,PROJECTION,DATUM,INV_OWNER,LAND_OWNER,PERMISSION,TENURE_TYPE,INV_TYPE,INV_VERSION,INV_START_YR,INV_FINISH_YR,INV_ACQ_ID,INV_ACQ_YR,INV_UPDATE_YR,COMMENT##\n";

	
	my $HDR_Record =  "1,SK,UTM (Mapsheet),UTM,NAD83,PROV_GOV,,,,UTM,,1985,1995,,,,";
	print CASHDR $HDR_Record . "\n";
	#close(INFOHDR);  
	}
	else 	{
		
		open (CASCAS, ">>$CAS_File_CAS") || die "\n Error: Could not open GROUPCAS  output file!\n";
		open (CASLYR, ">>$CAS_File_LYR") || die "\n Error: Could not open GROUPCAS layer output file!\n";
		open (CASNFL, ">>$CAS_File_NFL") || die "\n Error: Could not open GROUPCAS non-forested file!\n";
		open (CASDST, ">>$CAS_File_DST") || die "\n Error: Could not open GROUPCAS disturbance  file!\n";
		open (CASECO, ">>$CAS_File_ECO") || die "\n Error: Could not open GROUPCAS ecological  file!\n";
		open (CASHDR, ">>$CAS_File_HDR") || die "\n Error: Could not open CAS header output file!\n";
		#open (INFOHDR, "<$INFOHDR_File") || die "\n Error: Could not open file $INFOHDR_File !\n";
	}

my $nbpr=0;
my $total=0;	
my $total2=0;	
my $Record; my @Fields;my $PolyNum; my $CAS_ID; my $MapSheetID; my $IdentifyID;my $Area; my $Perimeter;
	my $Mer;my $Rng;my $Twp;my $MoistReg; my $Height;
	my $SpAss; my $Sp1;my $Sp2;my $Sp3; my $Sp4;my $Sp5;
	my $Sp1Per;my $Sp2Per;my $Sp3Per;  my $Sp4Per; my $Sp5Per; 
	my $CrownClosure;
	my $Origin;
	my $Dist; 
	my $Dist1;
	my $Dist2;
	my $Dist3;
	my $WetEco;  my $Ecosite;my $SMR;my $StandStructureCode;
	my $CCHigh;my $CCLow;
	my $SpeciesComp; my $SpComp; 
	my $SiteClass; my $SiteIndex;
	my $Wetland;  
	my $NatNonVeg; 
    my $NonForVeg; 
    my $UnprodFor; 
	my %herror=();
	my $keys;
    my $USp1; 
    my $RSp1;
    my $USp2; 
    my $RSp2;
	
	my $PHOTO_YEAR;
	my $NonVegAnth;
	my $NonProdFor;    
	my $SoilText; 
	my $UnProdFor;
    my $HeightHigh ;
    my $HeightLow;  
    my $OriginHigh; 
    my $OriginLow;    
    my @ListSp; 
    my $Mod; 
    my $ModYr; 
    my $NonProd; 
    my $Drain;

my $CAS_Record; my $Lyr_Record; my $LYR_Record1; my $LYR_Record2; my $LYR_Record3;
my $NFL_Record; my $NFL_Record1; my $NFL_Record2; my $NFL_Record3; my $DST_Record; 
my  @SpecsPerList=();
my $errspec; 
my $Spc1;my $Spc2;my $Spc3; my $Spc4;my $Spc5;
my $cpt_ind;
##############################################

	my $csv = Text::CSV_XS->new({  binary              => 1,
				   });
        open my $SKinv, "<", $SK_File or die " \n Error: Could not open QC input file $SK_File: $!";

 	my @tfilename= split ("/", $SK_File);
	my $nps=scalar(@tfilename);
	$Glob_filename= $tfilename[$nps-1];
	
	$csv->column_names ($csv->getline ($SKinv));

   	while (my $row = $csv->getline_hr ($SKinv)) {	#print "CAS_ID is $row->{CAS_ID}  and AREA is $row->{AREA} \n"; #exit(0);

	
#################################################################
#CAS_ID	HEADER_ID	OBJECTID	MAP	MAPFID	AREA	PERIMETER	SYR	PREFID	OWNER	CZONE	SOURCE	SA	SP10	SP11	SP20	HGT	D	YOO	SP12	SP21	U1	U2	MLEVEL	YSP	R1	R2	DRAIN	TEXT	DIST	DYR	NP	OLDST	ORGAREA	FCT	CT_SA	HT	DC	OWNER_TYPE	PFT	Age																																																																																																																																																																																																																							
           
			$Glob_CASID   =  $row->{CAS_ID};
		 $CAS_ID       =  $row->{CAS_ID};
		 $IdentifyID   =  $row->{HEADER_ID};
		 $PolyNum      =  $row->{OBJECTID};
         	 $MapSheetID   =  $row->{MAP};
         	 $Area         =  $row->{SHAPE_AREA};
	 	 $Perimeter    =  $row->{SHAPE_PERI};
  
 		 $SpAss	=  $row->{SA};
		 $Sp1=  $row->{SP10};
		 $Sp2=  $row->{SP11}; 
		 $Sp3=  $row->{SP12};
		 $Sp4=  $row->{SP20};
		 $Sp5=  $row->{SP21};

	 	 $Height      =  $row->{HGT};
		 $CrownClosure      =  $row->{D};
		 $Origin       =  $row->{YOO};

		 $USp1=  $row->{U1};
		 $USp2=  $row->{U2};

		 $RSp1=  $row->{R1};
		 $RSp2=  $row->{R2};
		 	
 		 $Drain =  $row->{DRAIN};
		 $SoilText=$row->{TEXT};
		 $MoistReg     =  $row->{DRAIN};
 		 $Mod=  $row->{DIST};
		 $ModYr =  $row->{DYR};
 		 $NonProd =  $row->{NP};

	     	 $PolyNum =$row->{OBJECTID};
	     
	     	 $PHOTO_YEAR   =  $row->{SYR};
	     	 if ($PHOTO_YEAR eq "0" || $PHOTO_YEAR eq "") {$PHOTO_YEAR = MISSCODE;}
		 elsif(length ($PHOTO_YEAR) !=4) {
				$keys="lenght of photoyear"."#".$PHOTO_YEAR;
				$herror{$keys}++;
				$PHOTO_YEAR=$PHOTO_YEAR + 1900;
			}

		 if ($ModYr eq "0" || $ModYr eq "") {}
		 elsif(length ($ModYr) !=4) {
				$keys="lenght of dist_year"."#".$ModYr;
				$herror{$keys}++;
				$ModYr=$ModYr + 1900;
			}

		 $SMR = SoilMoistureRegime($row->{DRAIN});
	  	 if($SMR eq ERRCODE) { 	
					$keys="MoistReg"."#".$row->{DRAIN};
					$herror{$keys}++;		
		}

	  	$StandStructureCode = "S";
	

	  	$CCHigh = CCUpper($row->{D});
	  	$CCLow = CCLower($row->{D});
	 	if($CCHigh  eq ERRCODE   || $CCLow  eq ERRCODE) { $keys="Density"."#".$row->{D};
						     $herror{$keys}++;
						}
	 
	  	$HeightHigh = StandHeightUp($row->{HGT});
	  	$HeightLow = StandHeightLow($row->{HGT});
		if($HeightHigh  eq ERRCODE   || $HeightLow  eq ERRCODE || $HeightHigh  eq MISSCODE   || $HeightLow  eq MISSCODE) { 

					if ($row->{SP10} eq "" &&  ($row->{HGT} eq "0" || $row->{HGT} eq "")){
									$HeightHigh=UNDEF;
									$HeightLow =UNDEF;
					}
					else {
							$keys="Height"."#".$row->{HGT};
						     	$herror{$keys}++;
							 	
					}
	 }
	$errspec=0;
	  $SpeciesComp = Species_UTM($row->{SA},$row->{SP10}, $row->{SP11}, $row->{SP12}, $row->{SP20}, $row->{SP21}, $spfreq);

if($SpeciesComp =~ m/^#/){$keys="error translating ".$SpeciesComp."#original#".$row->{SP10}.",".$row->{SP11}.",".$row->{SP12}.",".$row->{SP20}.",".$row->{SP21};
			$herror{$keys}++; 
$Wetland=MISSCODE;
}
elsif($SpeciesComp =~ m/^!/){$keys="undefined config ".$SpeciesComp."#original#".$row->{SP10}.",".$row->{SP11}.",".$row->{SP12}.",".$row->{SP20}.",".$row->{SP21};
			$herror{$keys}++; 
$Wetland=MISSCODE;
}
else {
 	  @SpecsPerList  = split(",", $SpeciesComp); 
	  #$Spc1=$SpecsPerList[0];$Spc2=$SpecsPerList[2];$Spc3=$SpecsPerList[4];$Spc4=$SpecsPerList[6];$Spc5=$SpecsPerList[8];
 
   			for($cpt_ind=0; $cpt_ind<=4; $cpt_ind++)
				{  
					my $posi=$cpt_ind*2;
					
        		  		if($SpecsPerList[$posi] eq SPECIES_ERRCODE ) 
						{ 
							$errspec=1;
						}
   				}
	if($errspec==1){
			$keys="species".$SpeciesComp."#original#".$row->{SP10}.",".$row->{SP11}.",".$row->{SP12}.",".$row->{SP20}.",".$row->{SP21};
			$herror{$keys}++; 
		}
	my $total=$SpecsPerList[1] + $SpecsPerList[3]+ $SpecsPerList[5] +$SpecsPerList[7] +$SpecsPerList[9];
	
	if($total != 100 && $total != 0 ){
			$keys="Stotal perct !=100"."#$total#".$SpeciesComp."#original#".$row->{SP10}.",".$row->{SP11}.",".$row->{SP12}.",".$row->{SP20}.",".$row->{SP21};
			$herror{$keys}++; 
			#$errspec=1;
	}

	  $SpeciesComp = $SpeciesComp .",XXXX UNDF,0,XXXX UNDF,0,XXXX UNDF,0,XXXX UNDF,0,XXXX UNDF,0";
 $Sp1Per= $SpecsPerList[1];
	 
	  $Wetland = WetlandCodes_UTM ($row->{DRAIN},  $row->{TEXT}, $row->{D},  $row->{NP}, $row->{SP10}, $row->{SP11}, $Sp1Per);

    }

	  $OriginHigh = UpperOrigin($row->{YOO});
	  $OriginLow = LowerOrigin($row->{YOO});
	  
	  if($OriginHigh   eq ERRCODE   || $OriginLow  eq ERRCODE ) { 
									if ($row->{SP10} eq "" &&  ($row->{YOO} eq "0" || $row->{YOO} eq "")){
										$OriginHigh=UNDEF;
										$OriginLow =UNDEF;
									}
									elsif ($row->{YOO} ne "0" && $row->{YOO} ne "") {
										$keys="Origin"."#".$row->{YOO};
						     				$herror{$keys}++;
									}
	  }
 	  if( ($OriginHigh< $OriginLow) || $OriginHigh>2010 || ($OriginHigh <1700 && $OriginHigh >0) || ($OriginLow <1700 && $OriginLow >0) || $OriginLow>2010) { 
									$keys="bounds for Origin"."#".$row->{YOO};
						     			$herror{$keys}++;
	 }
	 if( (($OriginHigh>0) && length ($OriginHigh) !=4 )|| (($OriginLow>0) && length ($OriginLow)!=4)){
									$keys="computed Origin"."#".$OriginHigh."--".$OriginLow;
						     			$herror{$keys}++;
	 }

 	  $SiteClass = UNDEF; #"";
	  $SiteIndex = UNDEF; #"";
	  #$UnprodFor =UNDEF; #"";

	  #@SpecsPerList  = split(",", $SpeciesComp); 
 	 
	  
	  # ===== Non-forested Land =====
 
	  $NatNonVeg = NaturallyNonVegetated($row->{NP});
	  $NonForVeg = NonForested($row->{NP});  
	  $UnProdFor = UnprodForested ($row->{NP});
	  $NonVegAnth=NonVegetatedAnth($row->{NP});

	 if(($NatNonVeg  eq ERRCODE) && ($NonForVeg eq ERRCODE) &&  ($UnProdFor eq ERRCODE)&&  ($NonVegAnth eq ERRCODE)) { 
			$keys="NonForNonVeg"."#".$row->{NP};
			$herror{$keys}++;
	}
	  else {
			if ($NatNonVeg  eq ERRCODE) { 
				$NatNonVeg = MISSCODE;  				
			 }
	  		if ($NonForVeg  eq ERRCODE) { 
				$NonForVeg = MISSCODE;  				
			 }
	 		if ($UnProdFor  eq ERRCODE) { 
				$UnProdFor = MISSCODE;  				
	 		}
			if ($NonVegAnth  eq ERRCODE) { 
				$NonVegAnth = MISSCODE;  				
	 		}
		}

	  

	
	  # ===== Modifiers =====
	  $Dist1 = Disturbance($row->{DIST}, $row->{DYR});
	  my ($Cd1, $Cd2)=split(",", $Dist1);
	  if($Cd1 eq ERRCODE) { 
			$keys="disturbance"."#".$row->{DIST};
			$herror{$keys}++;
	  }
	  $Dist2 = MISSCODE.","."-1111,".MISSCODE. "," . MISSCODE;
	  $Dist3 = MISSCODE.","."-1111,".MISSCODE. "," . MISSCODE;
	  
	  #$Dist = $Dist1 . "," . UNDEF . "," . UNDEF;
	  #$Dist1 = $Dist1 . "," . MISSCODE . "," . MISSCODE;
          $Dist = $Dist1 . "," . $Dist2 . "," . $Dist3;
 
	  # ===== Output inventory info for layer 1 =====
	  #print ($StandStructureCode); exit;
	  
	  if (($StandStructureCode eq "S")) {
            $CAS_Record = $CAS_ID . "," . $PolyNum . "," . $StandStructureCode . ",1," . $IdentifyID . "," . $MapSheetID . "," . $Area . "," . $Perimeter . ",".$Area. ",".$PHOTO_YEAR;
	    print CASCAS $CAS_Record . "\n";
 		$nbpr=1;$$ncas++;$ncasprev++;

            #forested
	    if ($row->{SP10} ne "" || ($UnProdFor ne MISSCODE && $UnProdFor ne ERRCODE && $UnProdFor ne UNDEF)) {
	      $LYR_Record1 = $row->{CAS_ID} . "," . $SMR  . "," . MISSCODE . ",1,1";
	      $LYR_Record2 = $CCHigh . "," . $CCLow . "," . $HeightHigh . "," . $HeightLow . "," . $SpeciesComp;  # before speciescomp  . "," . $UnProdFor
	      $LYR_Record3 = $OriginHigh . "," . $OriginLow . "," . $SiteClass . "," . $SiteIndex ;
	      $Lyr_Record = $LYR_Record1 . "," . $LYR_Record2 . "," . $LYR_Record3;
	      print CASLYR $Lyr_Record . "\n";
		$nbpr++; $$nlyr++;$nlyrprev++;
	    }
            #non-foested
	    elsif ($NatNonVeg ne MISSCODE || $NonForVeg ne MISSCODE  || $NonVegAnth ne MISSCODE) {
	    #if ($UnProdFor ne MISSCODE || $NonForVeg ne MISSCODE || $UnProdFor ne MISSCODE) {
	      $NFL_Record1 = $row->{CAS_ID}. "," . $SMR  . "," . MISSCODE . ",1,1";
	      $NFL_Record2 = $CCHigh . "," . $CCLow . "," . $HeightHigh . "," . $HeightLow;
              $NFL_Record3 = $NatNonVeg . "," . $NonForVeg . "," . $NonVegAnth;  #	$UnProdFor;
              $NFL_Record = $NFL_Record1 . "," . $NFL_Record2 . "," . $NFL_Record3;
	      print CASNFL $NFL_Record . "\n";
		$nbpr++;$$nnfl++;$nnflprev++;
	    }
#new to avoid dropped records - 19-09-2012
	  elsif($row->{MLEVEL} eq "OP"){

	      $NFL_Record1 = $row->{CAS_ID}. "," . $SMR  . "," . MISSCODE . ",1,1";
	      $NFL_Record2 = $CCHigh . "," . $CCLow . "," . $HeightHigh . "," . $HeightLow;
              $NFL_Record3 = $NatNonVeg . "," . "OT" . "," . $NonVegAnth;   #previous UK NatNonveg code was there corrected by OT on 28 feb 2013
              $NFL_Record = $NFL_Record1 . "," . $NFL_Record2 . "," . $NFL_Record3;
	      print CASNFL $NFL_Record . "\n";
		$nbpr++;$$nnfl++;$nnflprev++;

	  }
 	elsif($row->{MLEVEL} eq ""){

	      $NFL_Record1 = $row->{CAS_ID}. "," . $SMR  . "," . MISSCODE . ",1,1";
	      $NFL_Record2 = $CCHigh . "," . $CCLow . "," . $HeightHigh . "," . $HeightLow;
              $NFL_Record3 = $NatNonVeg . "," . "ST" . "," . $NonVegAnth;  #	$UnProdFor;
              $NFL_Record = $NFL_Record1 . "," . $NFL_Record2 . "," . $NFL_Record3;
	      print CASNFL $NFL_Record . "\n";
		$nbpr++;$$nnfl++;$nnflprev++;

	  }
            #Disturbance
	    if ($row->{DIST} ne "") {
	      $DST_Record = $row->{CAS_ID} . "," . $Dist. ",1";
	      print CASDST $DST_Record . "\n";
		if($nbpr==1) {$$ndstonly++; $ndstonlyprev++;}
			$nbpr++;$$ndst++;$ndstprev++;
	    }
	   elsif ($row->{MLEVEL} eq "SIL" ||  $row->{MLEVEL} eq "EXP") {

 	      $Dist = "CO,-8888,-8888,-8888" . "," . $Dist2 . "," . $Dist3;
	      $DST_Record = $row->{CAS_ID} . "," . $Dist. ",1";
	      print CASDST $DST_Record . "\n";
		if($nbpr==1) {$$ndstonly++; $ndstonlyprev++;}
			$nbpr++;$$ndst++;$ndstprev++;
	    }
	    #Ecological 
	    if ($Wetland ne MISSCODE) {
	      $Wetland = $row->{CAS_ID} . "," . $Wetland."-";
	      print CASECO $Wetland . "\n";
		if($nbpr==1) {$$necoonly++;$necoonlyprev++;}
		$nbpr++;$$neco++;$necoprev++;
	    }
	  }

if($nbpr ==1 || $nbpr ==0){
			if($row->{SP10} eq ""  &&  $row->{DIST} eq ""  &&   $row->{NP} eq "" && $Wetland eq MISSCODE ) {
						
					$keys ="WILL PROBABLY DROP THIS>>>code for wetland DRAIN+=".$row->{DRAIN};
 					$herror{$keys}++; 
					
			}
			elsif($row->{SP10} eq ""  &&  $row->{DIST} eq "" && $row->{NP} eq "" ) {
						$keys ="WILL DROP instead of wetland".$row->{DRAIN};
 						$herror{$keys}++; 
			}
elsif($row->{SP10} eq ""  &&  $row->{DIST} eq "" && $row->{NP} eq "0") {
						$keys ="WILL DROP null NP, mlevel =".$row->{MLEVEL};
 						$herror{$keys}++; 
			}
			elsif($row->{SP10} eq "" ) {
						$keys ="WILL DROP instead nfl and dist-NP=".$row->{NP}."-distcode=".$row->{DIST};
 						$herror{$keys}++; 
			}
			else {

				$keys ="!!! record may be dropped#".$CAS_ID."bcse>>>specs=".$row->{SP10}."-distcode=".$row->{DIST}."-NPcode=".$row->{NP}."-wetcode=".$row->{DRAIN};
 				$herror{$keys}++; 
				$keys ="#droppable#";
 				$herror{$keys}++; 
			}
}


}

 $csv->eof or $csv->error_diag ();
  close $SKinv;

foreach my $k (sort {lc($a) cmp lc($b)} keys %$spfreq){
		$_ = $k;
		tr/a-z/A-Z/;
		my $upk = $_;
	 	print SPERRSFILE "cumulative frequency of species " ,$upk,  " is ", $spfreq->{$k},"\n";
		#print "invalid code " ,$k,  " found ", $herror{$k}," times\n";
  	}
	foreach my $k (keys %herror){
	 	print ERRS "invalid code " ,$k,  " found ", $herror{$k}," times\n";
		#print "invalid code " ,$k,  " found ", $herror{$k}," times\n";
	 }
	#close (SKinv);
	close (CASHDR);
	close (CASCAS);
	close (CASLYR);
	close (CASNFL);
	close (CASDST);
	close (CASECO);
	close(SPERRSFILE); close(SPECSLOGFILE); 
	close(ERRS);
$total=$nlyrprev+ $nnflprev+  $ndstprev + $necoprev;
$total2=$nlyrprev+ $nnflprev+  $ndstonlyprev + $necoonlyprev;
#if($total > $ncasprev) {print "must check this !!! \n";}
#print "$ncasprev, $nlyrprev, $nnflprev,  $ndstprev, $necoprev, $total\n";
#print " for this file, nb records in casfile : $ncasprev, lyrfile : $nlyrprev, nflfile : $nnflprev,  dstfile : $ndstprev($ndstonlyprev), ecofile : $necoprev($necoonlyprev)--- total (without .cas): $total($total2)\n";
}


1;
#province eq "SK";

