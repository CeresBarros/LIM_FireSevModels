package ModulesV4::SK_conversion06;


use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(&SKinv_to_CAS );

use strict;
use Text::CSV;
our $INV_version;
our $Species_table;	
use constant 
{
    INFTY =>-1,
    ERRCODE => -9999,
	SPECIES_ERRCODE => "XXXX ERRC",
	MISSCODE => -1111,
	UNDEF=> -8888
};


our $Glob_CASID;
our $Glob_filename;	

sub isempty
{
	my $val=shift(@_);
	if(!defined ($val))
	{
		return 1;
	}
	$val =~ s/\s//g;

	if($val eq "" || $val eq "NULL") {
		return 1;
	}
	else {
		return 0;
	}	
}

sub is_missing
{
	my $val=shift(@_);
		
	if($val eq MISSCODE || $val eq ERRCODE || $val eq UNDEF) 
	{
		return 1;
	}
	else 
	{
		return 0;
	}	
}
#Derive SoilMoistureRegime from drainage class and unproductive wetland classes
sub SoilMoistureRegime
{
	my %MoistRegList = ("VD", 1, "D", 1, "MF", 1, "F", 1, "VF", 1, "MM", 1, "M", 1, "VM", 1, "MW", 1, "W", 1, "VW", 1);
	my $SoilMoistureReg;

	my $MoistReg = shift(@_);
	

	if(isempty($MoistReg)) 
	{ 
		$SoilMoistureReg = MISSCODE; 
	}
	else
	{
		$_ = $MoistReg; tr/a-z/A-Z/; $MoistReg = $_;
		if ($MoistRegList {$MoistReg} ) 
		{ 
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
		}
		else { $SoilMoistureReg = ERRCODE; }
	}
	return $SoilMoistureReg;
}



sub StandStructure
{
	my $Struc;
	my %StrucList = ( "S", 1, "M", 1, "C", 1, "s", 1, "m", 1, "c", 1);
	my $StandStructure;

	($Struc) = shift(@_);
	$Struc = uc($Struc);
	if(isempty($Struc)) 
	{ 
		$StandStructure = "S";
	}
	elsif ($StrucList {$Struc} ) 
	{ 
		if (($Struc eq "s") || ($Struc eq "S"))               { $StandStructure = "S"; }
		elsif (($Struc eq "c") || ($Struc eq "C"))               { $StandStructure = "C"; }
		elsif (($Struc eq "m") || ($Struc eq "M"))               { $StandStructure = "M"; }	
	}
	else 
	{  
		$StandStructure = ERRCODE; 
	}

	return $StandStructure;
}

#Determine StandStructure from StrucVal
sub StandStructureValue
{
	my $StrucVal;
	my  $StandStructureValue;

	($StrucVal) = shift(@_);
	if  (isempty($StrucVal))         { $StandStructureValue = 0; }
	elsif (($StrucVal < 1)    || ($StrucVal > 9))   { $StandStructureValue = 0; }
	elsif (($StrucVal > 0)    && ($StrucVal < 10))  { $StandStructureValue = $StrucVal; }
	else {$StandStructureValue = ERRCODE; }
	return $StandStructureValue;
}


#Determine CCUpper from CC 
sub CCUpper 
{
	my $CCHigh;
	my $Density;
	my %DensityList = ( "a", 1, "b", 1, "c", 1, "d", 1, "A", 1, "B", 1, "C", 1, "D", 1);

	($Density) = shift(@_);
	if(isempty($Density)) 
	{ 
		$CCHigh = MISSCODE; 
	}
	elsif($Density <=100 && $Density >=0) {$CCHigh = $Density;}
	else {$CCHigh = ERRCODE; }
	
	return $CCHigh;
}

#Determine CCLower from CC
sub CCLower 
{
	my $CCLow;
	my $Density;
	my %DensityList = ("a", 1, "b", 1, "c", 1, "d", 1, "A", 1, "B", 1, "C", 1, "D", 1);

	($Density) = shift(@_);
	if(isempty($Density)) 
	{ 
		$CCLow = MISSCODE; 
	}
	elsif($Density <=100 && $Density >=0) {$CCLow = $Density;}
		
	else {$CCLow = ERRCODE; }
	return $CCLow;
}



#Determine stand height from HEIGHT	5   2.5 - 7.5	| 10   7.6-12.5	| 15  12.6 - 17.5  |	20   17.6 - 22.5 | 25    22.6-INFINITY	

sub StandHeightUp 
{
	my $Height;
	my %HeightList = ("0", 1, "5", 1, "05", 1,"10", 1, "15", 1, "20", 1, "25", 1);
	my $HUpp;

	($Height) = shift(@_);	
	if(isempty($Height)) 
	{ 
		$HUpp = MISSCODE; 
	}
	elsif($Height <=100 && $Height >0) {$HUpp =$Height+0.5;}
	else {$HUpp = ERRCODE; }
	
	return $HUpp;
}

#Determine lower bound stand height from HEIGHT  
sub StandHeightLow 
{
	my $Height;
	my %HeightList = ("0", 1, "5", 1, "05", 1, "10", 1, "15", 1, "20", 1, "25", 1);
	my $HLow;

	($Height) = shift(@_);	
	if(isempty($Height)) 
	{ 
		$HLow = MISSCODE; 
	} 
	elsif($Height <=100 && $Height >0) 
	{
		if($Height >=0.5) {$HLow =$Height-0.5;}
		else {$HLow = $Height;}
	}
	else {$HLow = ERRCODE; }
	
	
	return $HLow;	            		       
}


#this is a fonction to determine wheter the specis is a softwood or hardwood- used for further verification in species percentage determination
sub TypeForest 
{
	my $CurrentSpecies = shift(@_);
	my $GenusSpecies;

	if(isempty($CurrentSpecies)) { $GenusSpecies = MISSCODE; }

	else
	{
		$_ = $CurrentSpecies;
		tr/a-z/A-Z/;
		$CurrentSpecies = $_;

		if ($CurrentSpecies eq "GA")  { $GenusSpecies = "H"; }#H-Frax penn
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
		else  { $GenusSpecies = ERRCODE; }
	}
	return $GenusSpecies;
}



#Dertermine Latine name of species
sub Latine 
{
	my $CurrentSpecies = shift(@_);
	my $GenusSpecies;

	if(isempty($CurrentSpecies))  { $GenusSpecies = "XXXX MISS"; }
	else
	{
		$_ = $CurrentSpecies;
		tr/a-z/A-Z/;
		$CurrentSpecies = $_;

		if ($Species_table->{$CurrentSpecies}) { $GenusSpecies = $Species_table->{$CurrentSpecies}; }
		else 	 {$GenusSpecies = SPECIES_ERRCODE;  print SPECSLOGFILE "Illegal species code $CurrentSpecies,CAS_ID=$Glob_CASID,file=$Glob_filename\n";  } 
	}
	return $GenusSpecies;
}

#Determine Species from the 5 Species fields

sub Species_SFVI
{
	
	my ($Sp1,$Sp1Per,$Sp2,$Sp2Per,$Sp3,$Sp3Per,$Sp4,$Sp4Per,$Sp5,$Sp5Per,$Sp6,$Sp6Per,$spfreq) = @_;
	my $Species;
	my $CurrentSpec;
	

	$spfreq->{$Sp1}++;
	$spfreq->{$Sp2}++;
	$spfreq->{$Sp3}++;
	$spfreq->{$Sp4}++;
	$spfreq->{$Sp5}++;
	$spfreq->{$Sp6}++;

	$Sp1 = Latine($Sp1); $Sp2 = Latine($Sp2); $Sp3 = Latine($Sp3); $Sp4 = Latine($Sp4); $Sp5 = Latine($Sp5); $Sp6 = Latine($Sp6);
	if(isempty($Sp1Per))
	{
		$Sp1Per = 0;
	}
	if(isempty($Sp2Per))
	{
		$Sp2Per = 0;
	}
	if(isempty($Sp3Per))
	{
		$Sp3Per = 0;
	}
	if(isempty($Sp4Per))
	{
		$Sp4Per = 0;
	}
	if(isempty($Sp5Per))
	{
		$Sp5Per = 0;
	}
	if(isempty($Sp6Per))
	{
		$Sp6Per = 0;
	}
	$Sp1Per *= 10; $Sp2Per *= 10; $Sp3Per *= 10; $Sp4Per *= 10; $Sp5Per *= 10; $Sp6Per *= 10;

	my  $total = $Sp1Per + $Sp2Per + $Sp3Per + $Sp4Per + $Sp5Per + $Sp6Per;
	if ($total == 90 && $Sp6Per == 0)
	{
		$Sp6Per = 10;
	}
	$Species = $Sp1 . "," . $Sp1Per . "," . $Sp2 . "," . $Sp2Per . "," . $Sp3 . "," . $Sp3Per . "," . $Sp4 . "," . $Sp4Per . "," . $Sp5 . "," . $Sp5Per. "," . $Sp6 . "," . $Sp6Per;

	#$Species = $Sp1 . "," . $Sp1Per . "," . $Sp2 . "," . $sp2Per . "," . $Sp3 . "," . $sp3Per . "," . $Sp4 . "," . $sp4Per. "," . $Sp5 . "," . $sp5Per;

	return $Species;

}


sub Species_UTM
{
	my $SpAssoc = shift(@_);
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

	if(isempty($Sp1) !=1 ){$nnsp1++;$notnull++;}
	if(isempty($Sp2) !=1 ){$nnsp1++;$notnull++;}
	if(isempty($Sp3) !=1 ){$nnsp1++;$notnull++;}
	if(isempty($Sp4) !=1 ){$nnsp2++;$notnull++;}
	if(isempty($Sp5) !=1 ){$nnsp2++;$notnull++;}

	if($SpAssoc eq "S" || $SpAssoc eq "H")
	{
		if($notnull==1)
		{
			$Sp1Per=100;$Sp2Per=0;$Sp3Per=0;$Sp4Per=0;$Sp5Per=0;
			if(isempty($Sp1))
			{
				return "-11,"."$Sp1".","."$Sp2".","."$Sp3".","."$Sp4".","."$Sp5";
			}
		}
		elsif($notnull==2)
		{  
					
					if($nnsp1==1 && $nnsp2==1)
					{
						$Sp1Per=80;$Sp2Per=0;$Sp3Per=0;$Sp4Per=20;$Sp5Per=0;
						if(isempty($Sp1) || isempty($Sp4))
						{
							return "#121,"."$Sp1".","."$Sp2".","."$Sp3".","."$Sp4".","."$Sp5";
						}
					}
					elsif($nnsp1==2 && (( $Sp1 ne "JP" &&    $Sp2 ne "BS") || ($Sp2 ne "BS" || $Sp2 ne "JP" )) )
					{		
						$Sp1Per=70;$Sp2Per=30;$Sp3Per=0;$Sp4Per=0;$Sp5Per=0;
						if(isempty($Sp1) || isempty($Sp2))
						{
							return "#122,"."$Sp1".","."$Sp2".","."$Sp3".","."$Sp4".","."$Sp5";
						}
					}
					elsif($nnsp1==2 && ( $Sp1 eq "JP" || $Sp1 eq "BS")  &&  ($Sp2 eq "BS" || $Sp2 eq "JP" ))
					{		
						$Sp1Per=60;$Sp2Per=40;$Sp3Per=0;$Sp4Per=0;$Sp5Per=0;
					}
					else {return "!!!!undefined config1";}
		}
		elsif($notnull==3)
		{
					if($nnsp1==3){
							$Sp1Per=40;$Sp2Per=30;$Sp3Per=30;$Sp4Per=0;$Sp5Per=0;
							if(isempty($Sp1) || isempty($Sp2) || isempty($Sp3))
							{
								return "#131,"."$Sp1".","."$Sp2".","."$Sp3".","."$Sp4".","."$Sp5";
							}
					}
					elsif($nnsp1==2) {
							$Sp1Per=50;$Sp2Per=30;$Sp3Per=0;$Sp4Per=20;$Sp5Per=0;
							if(isempty($Sp1) || isempty($Sp2) || isempty($Sp4))
							{
								return "#132,"."$Sp1".","."$Sp2".","."$Sp3".","."$Sp4".","."$Sp5";
							}
					}
					elsif($nnsp1==1) 
					{
						$Sp1Per=70;$Sp2Per=0;$Sp3Per=0;$Sp4Per=20;$Sp5Per=10;
						if(isempty($Sp1) || isempty($Sp4) || isempty($Sp5))
						{
							return "#133,"."$Sp1".","."$Sp2".","."$Sp3".","."$Sp4".","."$Sp5";
						}
					}
					else {return "!!!!undefined config2";}
		} 
		elsif($notnull==4)
		{
					if($nnsp1==2)
					{
						$Sp1Per=40;$Sp2Per=30;$Sp3Per=0;$Sp4Per=20;$Sp5Per=10;
						if(isempty($Sp1) || isempty($Sp2) || isempty($Sp4) || isempty($Sp5))
						{
							return "#141,"."$Sp1".","."$Sp2".","."$Sp3".","."$Sp4".","."$Sp5";
						}
					}
					elsif($nnsp1==3) 
					{
						$Sp1Per=50;$Sp2Per=20;$Sp3Per=20;$Sp4Per=10;$Sp5Per=0;
						if(isempty($Sp1) || isempty($Sp2) || isempty($Sp3) || isempty($Sp4))
						{
							return "#142,"."$Sp1".","."$Sp2".","."$Sp3".","."$Sp4".","."$Sp5";
						}
					}
					else {return "!!!!undefined config3";}
		} 
		elsif($notnull==5){
					 
					$Sp1Per=40;$Sp2Per=20;$Sp3Per=20;$Sp4Per=10;$Sp5Per=10;
						if(isempty($Sp1) || isempty($Sp2) || isempty($Sp3) || isempty($Sp4) || isempty($Sp5))
						{
							return "#15,"."$Sp1".","."$Sp2".","."$Sp3".","."$Sp4".","."$Sp5";
						}
		}
	} 
	elsif($SpAssoc eq "SH" || $SpAssoc eq "HS")
	{
		if($notnull==2)
		{  
					if($nnsp1==2)
					{
						$Sp1Per=60;$Sp2Per=40;$Sp3Per=0;$Sp4Per=0;$Sp5Per=0;
						if(isempty($Sp1) || isempty($Sp2))
						{
							return "#22,"."$Sp1".","."$Sp2".","."$Sp3".","."$Sp4".","."$Sp5";
						}
					}
					elsif($nnsp1==1 && $nnsp2==1) 
					{
						$Sp1Per=65;$Sp2Per=0;$Sp3Per=0;$Sp4Per=35;$Sp5Per=0;
						if(isempty($Sp1) || isempty($Sp4))
						{
							return "#23,"."$Sp1".","."$Sp2".","."$Sp3".","."$Sp4".","."$Sp5";
						}
					 	# return "#this from BK ---SH  first 2 species are not primary "."$Sp1".","."$Sp2".","."$Sp3".","."$Sp4".","."$Sp5\n";
					}
					else {return "!!!!undefined config4";}
		}
		elsif($notnull==3)
		{
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
							if(isempty($Sp1) || isempty($Sp2) || isempty($Sp4))
							{
									return "#24,"."$Sp1".","."$Sp2".","."$Sp3".","."$Sp4".","."$Sp5";
							}
					}
					elsif($nnsp1==1 && $nnsp2==2) 
					{
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
							if(isempty($Sp1) || isempty($Sp4) || isempty($Sp5))
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
		elsif($notnull==4)
		{
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
		elsif($notnull==5)
		{
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
			else 
			{
				return "!!!!undefined config11";
			}
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

#Determine upper stand origin from Origin
sub UpperOrigin 
{
	my $Origin;
	my $firstdgt;
	($Origin) = shift(@_);


	if(isempty($Origin)) 
	{ 
		$Origin = MISSCODE; 
	}
	elsif ($Origin > 0) 
	{
		if ($INV_version eq "UTM") 
		{
			$firstdgt = substr $Origin, 0, 1 ;
			if ($firstdgt == 8 ||$firstdgt==9 ) 
			{ 
				$Origin = $Origin+100;
 	 			$Origin = $Origin*10;
				$Origin = $Origin + 5;
			}
	      	elsif ($firstdgt == 1) {$Origin = $Origin + 5; }
	     	else {$Origin = ERRCODE;}
		}
		elsif ($INV_version eq "SFVI")
		{
		    if (($Origin % 10) > 0) { $Origin = $Origin; }
			else  { $Origin = $Origin + 5; }
		}		
	}
	else 
	{ $Origin = ERRCODE; }

	return $Origin;
}

#Determine lower stand origin from Origin
sub LowerOrigin 
{
	my $Origin;
	my $firstdgt;
	($Origin) = shift(@_);


	if(isempty($Origin)) 
	{ 
		$Origin = MISSCODE; 
	}
	elsif ($Origin > 0) 
	{
		if ($INV_version eq "UTM") 
		{
			$firstdgt=substr $Origin, 0, 1 ;
			if ($firstdgt == 8 ||$firstdgt==9 )
			{ 
				$Origin = $Origin+100;
 	 			$Origin = $Origin*10;
				$Origin = $Origin -4;
			}
	       	elsif ($firstdgt == 1) {$Origin = $Origin -4 ;  }
	      	else {$Origin = ERRCODE;}
		}
		elsif ($INV_version eq "SFVI") 
		{
	 		if (($Origin % 10) > 0) { $Origin = $Origin; }
	 		else  { $Origin = $Origin-4; }
		}
	}
	else { $Origin = ERRCODE; }

	return $Origin;
}



#UnProdForest TM,TR, ?OM, AL, SD, SC, NP, 
sub UnprodForested 
{
	my $UnprodFor;
	my %UnprodForList = ("0", 1, "3100", 1, "3200", 1, "3900", 1   );


	($UnprodFor) = shift(@_);
	
	if($INV_version eq "UTM")
	{
					if  ($UnprodFor eq "0" || isempty($UnprodFor))	{ $UnprodFor = MISSCODE; }
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

sub NaturallyNonVegetated
{
	my $NatNonVeg;
	
	my $NVSL = shift(@_);
	my $AQCL = shift(@_);

	if(isempty($AQCL))
	{ 
		$NatNonVeg = uc($NVSL);
	}
	else 
	{ 
		$NatNonVeg = uc($AQCL);
	}
#	if ($NatNonVegList {$NatNonVeg} ) { } else { $NatNonVeg = ERRCODE; }

	
	if  (isempty($NatNonVeg))	{ $NatNonVeg = MISSCODE; }

	elsif (($NatNonVeg eq "LA"))	{ $NatNonVeg = "LA"; }
	elsif (($NatNonVeg eq "RI"))	{ $NatNonVeg = "RI"; }
	elsif (($NatNonVeg eq "FL") || ($NatNonVeg eq "SF" ))	{ $NatNonVeg = "FL"; }


	elsif (($NatNonVeg eq "RK"))	{ $NatNonVeg = "RK"; }
	elsif (($NatNonVeg eq "CB"))	{ $NatNonVeg = "SL"; } # prev EX
	elsif (($NatNonVeg eq "MS"))	{ $NatNonVeg = "EX"; }
	elsif (($NatNonVeg eq "SB") || ($NatNonVeg eq "RF"))	{ $NatNonVeg = "WS"; }
	elsif (($NatNonVeg eq "SA"))	{ $NatNonVeg = "BE"; } # if adj to water
	# #elsif (($NatNonVeg eq "SA"))	{ $NatNonVeg = "SA"; } # if not adj to water -- SA do not exist
	elsif (($NatNonVeg eq "UK"))	{ $NatNonVeg = "OT"; }
	

	elsif (($NatNonVeg eq "GR"))	{ $NatNonVeg = "WS"; }
	elsif (($NatNonVeg eq "WA"))	{ $NatNonVeg = "LA"; }
	elsif (($NatNonVeg eq "ST"))	{ $NatNonVeg = "RI"; }
	elsif (($NatNonVeg eq "SL"))	{ $NatNonVeg = "FL"; }


	elsif (($NatNonVeg eq "FP"))	{ $NatNonVeg = "BP"; }
	
	else { $NatNonVeg = ERRCODE; }
	
	return $NatNonVeg;
}

#3100  TREED MUSKEG  Treed Muskeg= TM	  3200  TREED ROCK  Treed Rock=TR #3800  SAND  Sand=SD  3400  CLEAR ROCK Clear Rock=RK	3700  CLEARING  Clearing =OT  5100  FLOODED LAND  Flooded=FL  5210  WATER-LAKE SURFACE  Lake=LA	 5220  WATER-RIVER SURFACE   Large Stream=RI #3300  CLEAR MUSKEG  Clear Muskeg=OM  3500  BRUSHLAND  Brushland=ST 3600  MEADOW  Meadow=HG  3900  NON PRODUCTIVE BURN-OVER  Non Productive Burn=SD 4000  PASTURE LAND  Pasture or Cropland = CL  #5200  WATER-UNKNOWN SURFACE 	#9000  NOT TYPED	
									
#NonForestedVeg ---ST, SL, HF, HE, HG, BR, OM, BT
#Determine Non-forested vegetation stands  from NP
sub NonForested
{
	
	my %NonForVegList = ("TS", 1, "LS", 1, "NE", 1, "FE", 1, "GR", 1, "MO", 1, "LI", 1, "AV", 1);
	my $NonForVeg;
	my ($SHRUB1,$SHR_CC,$HERBS1,$HB_CC,$SMR,$L1CC,$L2CC,$L3CC) = @_;
	my $cond2 = 1;
	 
	if(isempty($SHR_CC))
	{ 
		$SHR_CC = 0;
		$cond2 = 0;
	}
	if(isempty($HB_CC))
	{ 
		$HB_CC = 0;
		$cond2 = 0;
	}
	if(isempty($L1CC))
	{ 
		$L1CC = 0;
	}
	if(isempty($L2CC))
	{ 
		$L2CC = 0;
	}
	if(isempty($L3CC))
	{ 
		$L3CC = 0;
	}

	if(isempty($SHRUB1))
	{ 
		$SHRUB1 = "";
	}
	else 
	{ 
		$SHRUB1 = uc($SHRUB1);
	}

	if(isempty($HERBS1))
	{ 
		$HERBS1 = "";
	}
	else 
	{ 
		$HERBS1 = uc($HERBS1);
	}

	if(isempty($SMR))
	{ 
		$SMR = "";
	}
	else 
	{ 
		$SMR = uc($SMR);
	}
	my $sumCC  = $L1CC + $L2CC + $L3CC ;

	if($sumCC < 10 && ($cond2 && $SHR_CC >= $HB_CC))
	{
		$NonForVeg = $SHRUB1;
		if (isempty($NonForVeg))	{ $NonForVeg = MISSCODE; } 
		elsif (($NonForVeg eq "TS"))	{ $NonForVeg = "ST"; } #TS turn into ST
		elsif (($NonForVeg eq "AL"))	{ $NonForVeg = "ST"; }
		elsif (($NonForVeg eq "BH"))	{ $NonForVeg = "ST"; }
		elsif (($NonForVeg eq "MA"))	{ $NonForVeg = "ST"; }
		elsif (($NonForVeg eq "SA"))	{ $NonForVeg = "ST"; }
		elsif (($NonForVeg eq "PC"))	{ $NonForVeg = "ST"; }
		elsif (($NonForVeg eq "CR"))	{ $NonForVeg = "ST"; }
		elsif (($NonForVeg eq "WI"))	{ $NonForVeg = "ST"; }

		elsif (($NonForVeg eq "LS"))	{ $NonForVeg = "SL"; }
		elsif (($NonForVeg eq "RO"))	{ $NonForVeg = "SL"; }
		elsif (($NonForVeg eq "BI"))	{ $NonForVeg = "SL"; }
		elsif (($NonForVeg eq "BU"))	{ $NonForVeg = "SL"; }
		elsif (($NonForVeg eq "DW"))	{ $NonForVeg = "SL"; }
		elsif (($NonForVeg eq "RA"))	{ $NonForVeg = "SL"; }
		elsif (($NonForVeg eq "CU"))	{ $NonForVeg = "SL"; }
		elsif (($NonForVeg eq "SN"))	{ $NonForVeg = "SL"; }
		elsif (($NonForVeg eq "BB"))	{ $NonForVeg = "SL"; }
		elsif (($NonForVeg eq "CI"))	{ $NonForVeg = "SL"; }
		elsif (($NonForVeg eq "BL"))	{ $NonForVeg = "SL"; }
		elsif (($NonForVeg eq "LA"))	{ $NonForVeg = "SL"; }
		elsif (($NonForVeg eq "LE"))	{ $NonForVeg = "SL"; }
		elsif (($NonForVeg eq "BE"))	{ $NonForVeg = "SL"; }
		elsif (($NonForVeg eq "LC"))	{ $NonForVeg = "SL"; }
		elsif (($NonForVeg eq "LB"))	{ $NonForVeg = "SL"; }

		# elsif (($NonForVeg eq "NE"))	{ $NonForVeg = "NE"; }#ask John is it HE?
		# elsif (($NonForVeg eq "FE"))	{ $NonForVeg = "NF"; }#ask John is it HF?
		# elsif (($NonForVeg eq "GR"))	{ $NonForVeg = "HG"; }
		# elsif (($NonForVeg eq "MO"))	{ $NonForVeg = "BR"; }
		# elsif (($NonForVeg eq "LI"))	{ $NonForVeg = "BR"; }
		# elsif (($NonForVeg eq "AV"))	{ $NonForVeg = "HF"; }
	}

	elsif($sumCC < 10 && ($cond2 = 1 && $SHR_CC < $HB_CC))
	{
		$NonForVeg = $HERBS1;
		if (isempty($NonForVeg))	{ $NonForVeg = MISSCODE; } 
		elsif (($NonForVeg eq "FE"))	{ $NonForVeg = "HF"; } #TS turn into ST
		elsif (($NonForVeg eq "HE"))	{ $NonForVeg = "HE"; }
		elsif (($NonForVeg eq "GR"))	{ $NonForVeg = "HG"; }
		elsif (($NonForVeg eq "MO"))	{ $NonForVeg = "BR"; }
		elsif (($NonForVeg eq "LI"))	{ $NonForVeg = "BR"; }
	}
	
	elsif($sumCC < 10 )
	{
		$NonForVeg = $SMR;
		if (isempty($NonForVeg))	{ $NonForVeg = MISSCODE; } 
		elsif (($NonForVeg eq "VM"))	{ $NonForVeg = "OM"; } #TS turn into ST
		elsif (($NonForVeg eq "MW"))	{ $NonForVeg = "OM"; }
		elsif (($NonForVeg eq "W"))	{ $NonForVeg = "OM"; }
		elsif (($NonForVeg eq "VW"))	{ $NonForVeg = "OM"; }
	}

	else { $NonForVeg = ERRCODE; }
	
	return $NonForVeg;
}


#Anthropogenic IN, FA, CL, SE, LG, BP, OT
#Determine Naturally non-vegetated stands
sub NonVegetatedAnth
{
	my $NonVegAnth;
	my %NatNonVegList = ("", 1, "ALA", 1, "AFS", 1, "POP", 1, "CEM", 1, "REC", 1, "PEX", 1, "TAR", 1, "GPI", 1, "RWC", 1, "BPI", 1, "RRC", 1, "MIS", 1, "TIC", 1, "ASA", 1,  "PLC", 1, "NSA", 1, "MPC", 1, "OIS", 1, "OUS", 1, "3700", 1, "9000", 1, "4000", 1, "UK", 1, "FP", 1);
	my $type = 0;


	my $LUC = shift(@_);
	my $AQCL = shift(@_);
	my $TRNSP = shift(@_);

	if(!isempty($LUC))
	{ 
		$NonVegAnth = uc($LUC);
		$type = 1;
	}
	elsif(!isempty($AQCL))
	{ 
		$NonVegAnth = uc($AQCL);
		$type = 2;
	}
	elsif(!isempty($TRNSP))
	{ 
		$NonVegAnth = uc($TRNSP);
		$type = 3;
	}

	if(isempty($NonVegAnth))	{ $NonVegAnth = MISSCODE;}
	elsif ($type == 3 ) { $NonVegAnth = "FA";}
	elsif ($type == 2 && ($NonVegAnth eq "DI" || $NonVegAnth eq "FP") ) {$NonVegAnth = "LG";}
	elsif ($type == 1)
	{
		if (($NonVegAnth eq "PEX"))	{ $NonVegAnth = "IN"; }
		elsif (($NonVegAnth eq "MIS"))	{ $NonVegAnth = "IN"; }
		elsif (($NonVegAnth eq "OIS"))	{ $NonVegAnth = "IN"; }
		elsif (($NonVegAnth eq "ASA"))	{ $NonVegAnth = "IN"; }
		elsif (($NonVegAnth eq "WEH"))	{ $NonVegAnth = "IN"; }
		elsif (($NonVegAnth eq "NSA"))	{ $NonVegAnth = "IN"; }
		elsif (($NonVegAnth eq "AFS"))	{ $NonVegAnth = "FA"; }
		elsif (($NonVegAnth eq "ALA"))	{ $NonVegAnth = "CL"; }
		elsif (($NonVegAnth eq "POP"))	{ $NonVegAnth = "SE"; }
		elsif (($NonVegAnth eq "CEM"))	{ $NonVegAnth = "SE"; }
		elsif (($NonVegAnth eq "BPI"))	{ $NonVegAnth = "BP"; }
		elsif (($NonVegAnth eq "GPI"))	{ $NonVegAnth = "BP"; }
		elsif (($NonVegAnth eq "REC"))	{ $NonVegAnth = "OT"; }
		elsif (($NonVegAnth eq "OUS"))	{ $NonVegAnth = "OT"; }
		elsif (($NonVegAnth eq "TOW"))	{ $NonVegAnth = "OT"; }
	}
	
	# elsif (($NonVegAnth eq "WEN"))	{ $NonVegAnth = "FA"; }
	# #elsif (($NonVegAnth eq "GPI")){ $NonVegAnth = "IN"; } prev
	# elsif (($NonVegAnth eq "RWC"))	{ $NonVegAnth = "FA"; }
	# elsif (($NonVegAnth eq "RRC"))	{ $NonVegAnth = "FA"; }
	# elsif (($NonVegAnth eq "TIC"))	{ $NonVegAnth = "FA"; }
	# elsif (($NonVegAnth eq "PLC"))	{ $NonVegAnth = "FA"; }
	# elsif (($NonVegAnth eq "MPC"))	{ $NonVegAnth = "FA"; }
	# elsif (($NonVegAnth eq "UK"))	{ $NonVegAnth = "OT"; }#moved from other type
	# elsif (($NonVegAnth eq "FP"))	{ $NonVegAnth = "BP"; }#moved from other type
	else { $NonVegAnth = ERRCODE; }
	
	return $NonVegAnth;
}


#Determine Disturbance from Modifiers
sub Disturbancepreviuous 
{
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

sub Disturbance
{
	my $ModCode;
	my $ModYr;
	#my $Extent="-8888,-8888";
	my $Mod;	
	my $Disturbance;
	
	my %ModList = ("CO", 1, "BO", 1, "SCO", 1, "WCO", 1, "OCO", 1, "OPC", 1, "WPC", 1, "SPC", 1, "WI", 1, "HA", 1, "IN", 1, "DI", 1, "AK", 1, "SL", 1, "SN", 1, "SI", 1,
				"co", 1, "bo", 1, "sco", 1, "wco", 1,  "wi", 1, "ha", 1, "in", 1, "di", 1, "ak", 1, "sl", 1, "sn", 1, "si", 1);
   
	($ModCode) = shift(@_);
	($ModYr) = shift(@_);
	if (isempty($ModYr))  {$ModYr = MISSCODE;}

	if (isempty($ModCode)) 
	{ 
		
		$Disturbance = MISSCODE.",-1111"; 
	}
	elsif ($ModList{$ModCode} ) 
	{ 

		
	 	if (($ModCode  eq "CO") || ($ModCode eq "co")) { $Mod="CO"; }
		elsif (($ModCode  eq "BO") || ($ModCode eq "bo")) { $Mod="BU"; }

		elsif($INV_version eq "SFVI")
		{
			if (($ModCode  eq "WI") || ($ModCode eq "wi")) { $Mod="WF"; }
			elsif (($ModCode  eq "HA") || ($ModCode eq "ha")) { $Mod="WE"; }
			elsif (($ModCode  eq "IN") || ($ModCode eq "in")) { $Mod="IK"; }
			elsif (($ModCode  eq "DI") || ($ModCode eq "di")) { $Mod="DI"; }
			elsif (($ModCode  eq "AK") || ($ModCode eq "ak")) { $Mod="OT"; }
			elsif (($ModCode  eq "SL") || ($ModCode eq "sl")) { $Mod="SL"; }
			elsif (($ModCode  eq "SN") || ($ModCode eq "sn")) { $Mod="OT"; }
			elsif (($ModCode  eq "SI") || ($ModCode eq "si")) { $Mod="SI"; }
			else { $Mod = ERRCODE; }
		}
		$Disturbance = $Mod . "," . $ModYr; 
		
	} 
	else 
	{ 
		$Mod = ERRCODE; $Disturbance = $Mod . "," . $ModYr;  
	}

	return $Disturbance;
}



#1-25	26-50	51-75	76-95	96-100	

sub DisturbanceExtUpper 
{
    my $ModExt;
    my $DistExtUpper;

	my %ModExtList = ( "1", 1, "2", 1, "3", 1, "4", 1, "5", 1);
	 
	($ModExt) = shift(@_);

	if (isempty($ModExt)) {$DistExtUpper = MISSCODE;} else { $DistExtUpper = ERRCODE; }

	
	if($INV_version eq "UTM")	{$DistExtUpper = MISSCODE; }
	elsif($INV_version eq "SFVI")
	{
		if (($ModExt eq "1"))  	       { $DistExtUpper = 25; }
		elsif (($ModExt eq "2"))                  { $DistExtUpper = 50; }
		elsif (($ModExt eq "3"))                  { $DistExtUpper = 75; }
		elsif (($ModExt eq "4"))                  { $DistExtUpper = 95; }
		elsif (($ModExt eq "5"))                  { $DistExtUpper = 100; }
	}
        return $DistExtUpper;
}

sub DisturbanceExtLower 
{
    my $ModExt;
    my $DistExtLower;

    my %ModExtList = ("1", 1, "2", 1, "3", 1, "4", 1, "5", 1);
	 
	($ModExt) = shift(@_);
	if (isempty($ModExt)) { $DistExtLower = MISSCODE; } else { $DistExtLower = ERRCODE; }

	if($INV_version eq "UTM")	{$DistExtLower = MISSCODE; }
	elsif($INV_version eq "SFVI"){
					if (($ModExt eq "1"))  	       { $DistExtLower = 1; }
					elsif (($ModExt eq "2"))                  { $DistExtLower = 26; }
					elsif (($ModExt eq "3"))                  { $DistExtLower = 51; }
					elsif (($ModExt eq "4"))                  { $DistExtLower = 76; }
					elsif (($ModExt eq "5"))                  { $DistExtLower = 96; }	
	}
       return $DistExtLower;
}


# Determine wetland codes
sub WetlandCodes_UTM 
{
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
	
	$_ = $Drain ; tr/a-z/A-Z/; $Drain  = $_;
	$_ = $SoilT; tr/a-z/A-Z/; $SoilT = $_;
	$_ = $CrownClosure; tr/a-z/A-Z/; $CrownClosure = $_;
	$_ =$NonProd;tr/a-z/A-Z/; $NonProd = $_;
	$_ = $Spec1; tr/a-z/A-Z/; $Spec1 = $_;
	$_ = $Spec2; tr/a-z/A-Z/; $Spec2 = $_;
	if (isempty($Spec1Per)) { $Spec1Per = 0; }
	 
	
	
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

sub WetlandCodes_SFVI 
{
	my ($Moist,$CrownClosure,$Height,$NonFor,$Spec1,$Spec2,$Spec1Per) =  @_;
	
	#my $Spec3 = shift(@_);
	#my $Spec4 = shift(@_);
	#my $Spec5 = shift(@_);
	

	my $WetlandCode = "";
	
	$_ = $Moist ; tr/a-z/A-Z/; $Moist  = $_;
	$_ = $Height; tr/a-z/A-Z/; $Height = $_;
	$_ = $CrownClosure; tr/a-z/A-Z/; $CrownClosure = $_;
	$_ = $NonFor;tr/a-z/A-Z/; $NonFor = $_;
	$_ = $Spec1; tr/a-z/A-Z/; $Spec1 = $_;
	$_ = $Spec2; tr/a-z/A-Z/; $Spec2 = $_;
	
	if (isempty($Spec1Per)) { $Spec1Per = 0; }
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
		  if ( (($Spec1 eq "BS") || ($Spec1 eq "TL") || ($Spec1 eq "WB") || ($Spec1 eq "MM") || ($Spec1 eq "BP"))  && (($Spec2 eq "BS") || ($Spec2 eq "TL") || ($Spec2 eq "WB") || ($Spec2 eq "MM") || ($Spec2 eq "BP")) &&  ($CrownClosure >= 50) && ($CrownClosure < 70) &&  ($Height >=12)) 
 			{ $WetlandCode = "S,T,N,N,"; }
		  elsif ( (($Spec1 eq "BS") || ($Spec1 eq "TL") || ($Spec1 eq "WB") || ($Spec1 eq "MM") || ($Spec1 eq "BP"))  && (($Spec2 eq "BS") || ($Spec2 eq "TL") || ($Spec2 eq "WB") || ($Spec2 eq "MM") || ($Spec2 eq "BP")) &&  ($CrownClosure >= 70) ) 
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



sub SKinv_to_CAS 
{
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

	if(($optgroups==0) || ($optgroups==1 && $nbiters==1)|| ($optgroups==2 && $TotalIT==1))
	{

		open (CASHDR, ">$CAS_File_HDR") || die "\n Error: Could not open CAS header output file!\n";
		open (CASCAS, ">$CAS_File_CAS") || die "\n Error: Could not open CAS common attribute schema  file!\n";
		open (CASLYR, ">$CAS_File_LYR") || die "\n Error: Could not open CAS layer output file!\n";
		open (CASNFL, ">$CAS_File_NFL") || die "\n Error: Could not open CAS non-forested land output file!\n";
		open (CASDST, ">$CAS_File_DST") || die "\n Error: Could not open CAS disturbance output file!\n";
		open (CASECO, ">$CAS_File_ECO") || die "\n Error: Could not open CAS ecological output file!\n";
		#open (INFOHDR, "<$INFOHDR_File") || die "\n Error: Could not open file $INFOHDR_File !\n";
	
	
		print CASCAS "CAS_ID,ORIG_STAND_ID,STAND_STRUCTURE,NUM_OF_LAYERS,IDENTIFICATION_ID,MAP_SHEET_ID,GIS_AREA,GIS_PERIMETER,INVENTORY_AREA,PHOTO_YEAR\n";
		print CASLYR "CAS_ID,SOIL_MOIST_REG,STRUCTURE_PER,LAYER,LAYER_RANK,CROWN_CLOSURE_UPPER,CROWN_CLOSURE_LOWER,HEIGHT_UPPER,HEIGHT_LOWER,PRODUCTIVE_FOR,". 		
		"SPECIES_1,SPECIES_PER_1,SPECIES_2,SPECIES_PER_2,SPECIES_3,SPECIES_PER_3,SPECIES_4,SPECIES_PER_4,SPECIES_5,SPECIES_PER_5,SPECIES_6,SPECIES_PER_6,SPECIES_7,SPECIES_PER_7,".
		"SPECIES_8,SPECIES_PER_8,SPECIES_9,SPECIES_PER_9,SPECIES_10,SPECIES_PER_10,ORIGIN_UPPER,ORIGIN_LOWER,SITE_CLASS,SITE_INDEX\n";
		print CASNFL "CAS_ID,SOIL_MOIST_REG,STRUCTURE_PER,LAYER,LAYER_RANK,CROWN_CLOSURE_UPPER,CROWN_CLOSURE_LOWER,HEIGHT_UPPER,HEIGHT_LOWER,NAT_NON_VEG,NON_FOR_ANTH,NON_FOR_VEG\n";
		print CASDST "CAS_ID,DIST_1,DIST_YR_1,DIST_EXT_UPPER_1,DIST_EXT_LOWER_1,DIST_2,DIST_YR_2,DIST_EXT_UPPER_2,DIST_EXT_LOWER_2,DIST_3,DIST_YR_3,DIST_EXT_UPPER_3,DIST_EXT_LOWER_3,LAYER\n";
		print CASECO "CAS_ID,WETLAND_TYPE,WET_VEG_COVER,WET_LANDFORM_MOD,WET_LOCAL_MOD,ECO_SITE\n";
		print CASHDR "IDENTIFICATION_ID,JURISDICTION,COORDINATE_SYS,PROJECTION,DATUM,INVENTORY_OWNER,LAND_OWNER,PERMISSION,TENURE_TYPE,INV_TYPE,INV_VERSION,INV_START_YR,INV_FINISH_YR,INV_ACQ_ID,INV_ACQ_YR,INV_UPDATE_YR\n";


	
		# ===== Output to header file =====
		#"IDENTIFICATION_ID,JURISDICTION,COORDINATE_SYS,PROJECTION,DATUM,INVENTORY_OWNER,LAND_OWNER,PERMISSION,TENURE_TYPE,INV_TYPE,INV_VERSION,INV_START_YR,INV_FINISH_YR,INV_ACQ_ID,INV_ACQ_YR,INV_UPDATE_YR\n";
			#print CASHDR 
		#"HEADER_ID,JURISDICTION,COORD_SYS,PROJECTION,DATUM,INV_OWNER,LAND_OWNER,PERMISSION,TENURE_TYPE,INV_TYPE,INV_VERSION,INV_START_YR,INV_FINISH_YR,INV_ACQ_ID,INV_ACQ_YR,INV_UPDATE_YR,COMMENT##\n";

	
		my $HDR_Record =  "1,SK,SFVI (Mapsheet),SFVI,NAD83,PROV_GOV,,,,SFVI,,1985,1995,,,";
		print CASHDR $HDR_Record . "\n";
		#close(INFOHDR);  
	}
	else 	
	{
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
	my $Sp11;my $Sp11Per; my $Sp12;my $Sp12Per; my $Sp13;my $Sp13Per; my $Sp14;my $Sp14Per; my $Sp15;my $Sp15Per; my $Sp16;my $Sp16Per;
	my $Sp21;my $Sp21Per; my $Sp22;my $Sp22Per; my $Sp23;my $Sp23Per; my $Sp24;my $Sp24Per; my $Sp25;my $Sp25Per; my $Sp26;my $Sp26Per;
	my $Sp31;my $Sp31Per; my $Sp32;my $Sp32Per; my $Sp33;my $Sp33Per; my $Sp34;my $Sp34Per; my $Sp35;my $Sp35Per; my $Sp36;my $Sp36Per;
	
	my $Sp2;my $Sp3; my $Sp4;my $Sp5;
	my $Sp1Per;my $Sp2Per;my $Sp3Per;  my $Sp4Per; my $Sp5Per; 
	my $CrownClosure1;my $CrownClosure2;my $CrownClosure3;
	my $Origin1;my $Origin2;my $Origin3;
	my $Dist; 
	my $Dist1;
	my $Dist2;
	my $Dist3;
	my $WetEco;  my $Ecosite;my $SMR;my $StandStructureCode;
	my $CCHigh1;my $CCLow1;my $CCHigh2;my $CCLow2;my $CCHigh3;my $CCLow3;
	my $SpeciesComp1; my $SpeciesComp2;my $SpeciesComp3;my $SpComp; 
	my $SiteClass; my $SiteIndex;
	my $Wetland;  
	my $NatNonVeg; 
    my $NonForVeg; 
    my $UnprodFor; 
	my %herror=();
	my $keys;
    	
	my $PHOTO_YEAR;
	my $NonVegAnth;
	my $NonProdFor;    
	
	my $UnProdFor;
	my $Height1;my $Height2;my $Height3;
    my $HeightHigh1;my $HeightHigh2;my $HeightHigh3;
    my $HeightLow1; my $HeightLow2; my $HeightLow3;  
    my $OriginHigh1; my $OriginHigh2; my $OriginHigh3; 
    my $OriginLow1; my $OriginLow2; my $OriginLow3;    
    my @ListSp; 
    my $Mod1; my $Mod2; my $Mod3; my $Mod1Ext; my $Mod2Ext; my $Mod3Ext; 
    my $ModYr1; my $ModYr2; my $ModYr3; 
    my $NonProd; 

	my $CAS_Record; my $Lyr_Record; my $LYR_Record1; my $LYR_Record2; my $LYR_Record3;
	my $NFL_Record; my $NFL_Record1; my $NFL_Record2; my $NFL_Record3; my $DST_Record; 
	my  @SpecsPerList=();
	my $errspec; 
	my $Spc1;my $Spc2;my $Spc3; my $Spc4;my $Spc5;
	my $cpt_ind; my $SpAss;
	my $SHRUB1; my $SHR_CC; my $HERBS1; my $HB_CC; my $NVSL; my $LUC; my $AQL; my $TRNSP;
	my  @Spreste3=(); my  @Spreste2=(); my  @Spreste1=();
	##############################################

	my $csv = Text::CSV_XS->new
	({  
		binary      => 1,
		sep_char    => ";" 
	});

    open my $SKinv, "<", $SK_File or die " \n Error: Could not open QC input file $SK_File: $!";

 	my @tfilename = split ("/", $SK_File);
	my $nps = scalar(@tfilename);
	$Glob_filename = $tfilename[$nps-1];
	
	$csv->column_names ($csv->getline ($SKinv));

   	while (my $row = $csv->getline_hr($SKinv)) 
   	{	
   		#print "CAS_ID is $row->{CAS_ID}  and AREA is $row->{AREA} \n"; #exit(0);	
		#################################################################
		#CAS_ID	HEADER_ID	OBJECTID	MAP	MAPFID	AREA	PERIMETER	SYR	PREFID	OWNER	CZONE	SOURCE	SA	SP10	SP11	SP20	HGT	D	YOO	SP12	SP21	U1	U2	MLEVEL	YSP	R1	R2	DRAIN	TEXT	DIST	DYR	NP	OLDST	ORGAREA	FCT	CT_SA	HT	DC	OWNER_TYPE	PFT	Age																																																																																																																																																																																																																							
	           
		$Glob_CASID   =  $row->{CAS_ID};
		$CAS_ID       =  $row->{CAS_ID};
		$IdentifyID   =  $row->{HEADER_ID};
		$PolyNum      =  $row->{POLY_NUM};
	    $MapSheetID   =  $row->{MAPSHEETNUM};
	    $Area         =  $row->{GIS_AREA};
		$Perimeter    =  $row->{GIS_PERI};
	  
	  	$Ecosite =  $row->{ECOSITE};
	 	$SpAss	=  $row->{CSG};
	 	#species, layer 1
		$Sp11 =  $row->{L1_SP1};
		$Sp11Per =  $row->{L1_SP1_COVER};
		$Sp12 =  $row->{L1_SP2};
		$Sp12Per =  $row->{L1_SP2_COVER};
		$Sp13 =  $row->{L1_SP3};
		$Sp13Per =  $row->{L1_SP3_COVER};
		$Sp14 =  $row->{L1_SP4};
		$Sp14Per =  $row->{L1_SP4_COVER};
		$Sp15 =  $row->{L1_SP5};
		$Sp15Per =  $row->{L1_SP5_COVER};
		$Sp16 =  $row->{L1_SP6};
		$Sp16Per =  $row->{L1_SP6_COVER};

		#species, layer 2
		$Sp21 =  $row->{L2_SP1};
		$Sp21Per =  $row->{L2_SP1_COVER};
		$Sp22 =  $row->{L2_SP2};
		$Sp22Per =  $row->{L2_SP2_COVER};
		$Sp23 =  $row->{L2_SP3};
		$Sp23Per =  $row->{L2_SP3_COVER};
		$Sp24 =  $row->{L2_SP4};
		$Sp24Per =  $row->{L2_SP4_COVER};
		$Sp25 =  $row->{L2_SP5};
		$Sp25Per =  $row->{L2_SP5_COVER};
		$Sp26 =  $row->{L2_SP6};
		$Sp26Per =  $row->{L2_SP6_COVER};

		#species, layer 3
		$Sp31 =  $row->{L3_SP1};
		$Sp31Per =  $row->{L3_SP1_COVER};
		$Sp32 =  $row->{L3_SP2};
		$Sp32Per =  $row->{L3_SP2_COVER};
		$Sp33 =  $row->{L3_SP3};
		$Sp33Per =  $row->{L3_SP3_COVER};
		$Sp34 =  $row->{L3_SP4};
		$Sp34Per =  $row->{L3_SP4_COVER};
		$Sp35 =  $row->{L3_SP5};
		$Sp35Per =  $row->{L3_SP5_COVER};
		$Sp36 =  $row->{L3_SP6};
		$Sp36Per =  $row->{L3_SP6_COVER};

		

		$CrownClosure1 =  $row->{L1_CROWN_CLOSURE};
		$Height1 =  $row->{L1_HEIGHT};
		$Origin1 =  $row->{L1_YOO};

		$CrownClosure2 =  $row->{L2_CROWN_CLOSURE};
		$Height2 =  $row->{L2_HEIGHT};
		$Origin2 =  $row->{L2_YOO};

		$CrownClosure3 =  $row->{L3_CROWN_CLOSURE};
		$Height3 =  $row->{L3_HEIGHT};
		$Origin3 =  $row->{L3_YOO};

		$MoistReg  =  $row->{SMR};
	 	
	 	$Mod1 =  $row->{DISTURBANCE_1};
	 	$Mod1Ext =  $row->{DISTURBANCE_EXTENT_1};
		$ModYr1 =  $row->{YOD_1};

		$Mod2 =  $row->{DISTURBANCE_2};
	 	$Mod2Ext =  $row->{DISTURBANCE_EXTENT_2};
		$ModYr2 =  $row->{YOD_2};

		$Mod3 =  $row->{DISTURBANCE_3};
	 	$Mod3Ext =  $row->{DISTURBANCE_EXTENT_3};
		$ModYr3 =  $row->{YOD_3};


	 	$NonProd =  $row->{TYPE};

	 	$SHRUB1 =  $row->{SHRUB1};
		$SHR_CC =  $row->{SHRUBS_CROWN_CLOSURE};
		$HERBS1 =  $row->{HERBS1};
		$HB_CC  =  $row->{HERBS_CROWN_CLOSURE}; 
		$NVSL = $row->{NVSL};
		$LUC = $row->{LUC};
		$AQL = $row->{AQUATIC_CLASS};
		$TRNSP =  $row->{TRANSP_CLASS};

		$PHOTO_YEAR   =  $row->{PHOTOYEAR}; #$row->{SYR};
		if ($PHOTO_YEAR eq "0" || isempty($PHOTO_YEAR)) {$PHOTO_YEAR = MISSCODE;}
		elsif(length ($PHOTO_YEAR) !=4) 
		{
			$keys="lenght of photoyear"."#".$PHOTO_YEAR;
			$herror{$keys}++;
			$PHOTO_YEAR=$PHOTO_YEAR + 1900;
		}

		if ($ModYr1 eq "0" ||isempty($ModYr1)) {$ModYr1 = MISSCODE;}
		elsif(length ($ModYr1) !=4) 
		{
			$keys="lenght of dist_year1"."#".$ModYr1;
			$herror{$keys}++;
			$ModYr1 = $ModYr1 + 1900;
		}

		if ($ModYr2 eq "0" ||isempty($ModYr2)) {$ModYr2 = MISSCODE;}
		elsif(length ($ModYr2) !=4) 
		{
			$keys="lenght of dist_year2"."#".$ModYr2;
			$herror{$keys}++;
			$ModYr2 = $ModYr2 + 1900;
		}

		if ($ModYr3 eq "0" ||isempty($ModYr3)) {$ModYr3 = MISSCODE;}
		elsif(length ($ModYr3) !=4) 
		{
			$keys="lenght of dist_year"."#".$ModYr3;
			$herror{$keys}++;
			$ModYr3 = $ModYr3 + 1900;
		}

		$SMR = SoilMoistureRegime($row->{SMR});
		if($SMR eq ERRCODE) 
		{ 	
			$keys="MoistReg"."#".$row->{SMR};
			$herror{$keys}++;		
		}


		$StandStructureCode = "S";
		$CCHigh1 = CCUpper($CrownClosure1);
		$CCLow1 = CCLower($CrownClosure1);
		if($CCHigh1  eq ERRCODE   || $CCLow1  eq ERRCODE) 
		{ 
			$keys="Density"."#".$CrownClosure1;
			$herror{$keys}++;
		}

		$CCHigh2 = CCUpper($CrownClosure2);
		$CCLow2 = CCLower($CrownClosure2);
		if($CCHigh2  eq ERRCODE   || $CCLow2  eq ERRCODE) 
		{ 
			$keys="Density"."#".$CrownClosure2;
			$herror{$keys}++;
		}

		$CCHigh3 = CCUpper($CrownClosure3);
		$CCLow3 = CCLower($CrownClosure3);
		if($CCHigh3  eq ERRCODE   || $CCLow3  eq ERRCODE) 
		{ 
			$keys="Density"."#".$CrownClosure3;
			$herror{$keys}++;
		}
	 


		$HeightHigh1 = StandHeightUp($Height1);
		$HeightLow1 = StandHeightLow($Height1);
		if($HeightHigh1  eq ERRCODE   || $HeightLow1  eq ERRCODE || $HeightHigh1  eq MISSCODE   || $HeightLow1  eq MISSCODE) 
		{ 
			if (isempty($row->{L1_SP1}) &&  ($Height1 eq "0" ||isempty($Height1)))
			{
				$HeightHigh1 = MISSCODE;
				$HeightLow1 = MISSCODE;
			}
			else 
			{
				$keys="Height1"."#".$Height1;
				$herror{$keys}++;			 	
			}
		}

		$HeightHigh2 = StandHeightUp($Height2);
		$HeightLow2 = StandHeightLow($Height2);
		if($HeightHigh2  eq ERRCODE   || $HeightLow2  eq ERRCODE || $HeightHigh2  eq MISSCODE   || $HeightLow2  eq MISSCODE) 
		{ 
			if (isempty($row->{L2_SP1}) &&  ($Height2  eq "0" || isempty($Height2)))
			{
				$HeightHigh2 = MISSCODE;
				$HeightLow2 = MISSCODE;
			}
			else 
			{
				$keys="Height2"."#".$Height2;
				$herror{$keys}++;			 	
			}
		}

		$HeightHigh3 = StandHeightUp($Height3);
		$HeightLow3 = StandHeightLow($Height3);
		if($HeightHigh3  eq ERRCODE   || $HeightLow3  eq ERRCODE || $HeightHigh3  eq MISSCODE   || $HeightLow3  eq MISSCODE) 
		{ 
			if (isempty($row->{L3_SP1}) &&  ($Height3 eq "0" || isempty($Height3)))
			{
				$HeightHigh3 = MISSCODE;
				$HeightLow3 = MISSCODE;
			}
			else 
			{
				$keys="Height3"."#".$Height3;
				$herror{$keys}++;			 	
			}
		}


		#species layer 1
		$errspec = 0;
		my $posi = 0;
		my $total = 0; 

		
		$SpeciesComp1 = Species_SFVI($Sp11,$Sp11Per,$Sp12,$Sp12Per,$Sp13,$Sp13Per,$Sp14,$Sp14Per,$Sp15,$Sp15Per,$Sp16,$Sp16Per,$spfreq);
		@SpecsPerList  = split(",", $SpeciesComp1); 
		for($cpt_ind=0; $cpt_ind<=5; $cpt_ind++)
		{  
			$posi=$cpt_ind*2;
		    if($SpecsPerList[$posi] eq SPECIES_ERRCODE ) 
			{ 
				$errspec=1;
			}
		}
		if($errspec == 1)
		{
			$keys="species layer 1".$SpeciesComp1."#original species#$CAS_ID".$Sp11.",".$Sp12.",".$Sp13.",".$Sp14.",".$Sp15.",".$Sp16;
			$herror{$keys}++; 
		}
		$total = $SpecsPerList[1] + $SpecsPerList[3]+ $SpecsPerList[5] +$SpecsPerList[7] +$SpecsPerList[9]+$SpecsPerList[11];
		
		if($total != 100 && $total != 0 )
		{
			$keys="Stotal perct !=100"."#$total#".$SpeciesComp1."#original percentages#".$Sp11Per.",".$Sp12Per.",".$Sp13Per.",".$Sp14Per.",".$Sp15Per.",".$Sp16Per;
			$herror{$keys}++; ;
			$herror{$keys}++; 
			#$errspec=1;
		}
		$SpeciesComp1 = $SpeciesComp1 .",XXXX UNDF,0,XXXX UNDF,0,XXXX UNDF,0,XXXX UNDF,0";
		$Sp1Per = $SpecsPerList[1]; 
		$Wetland = WetlandCodes_SFVI ($row->{SMR}, $row->{L1_CROWN_CLOSURE}, $row->{L1_HEIGHT},  $row->{TYPE}, $Sp11, $Sp12, $Sp1Per);
		

		#species layer 2
		$errspec = 0;
		$SpeciesComp2 = Species_SFVI($Sp21,$Sp21Per,$Sp22,$Sp22Per,$Sp23,$Sp23Per,$Sp24,$Sp24Per,$Sp25,$Sp25Per,$Sp26,$Sp26Per,$spfreq);
		@SpecsPerList  = split(",", $SpeciesComp2); 
		for($cpt_ind=0; $cpt_ind<=5; $cpt_ind++)
		{  
			$posi = $cpt_ind*2;
		    if($SpecsPerList[$posi] eq SPECIES_ERRCODE ) 
			{ 
				$errspec=1;
			}
		}
		if($errspec == 1)
		{
			$keys="species layer 2".$SpeciesComp2."#original species#".$Sp21.",".$Sp22.",".$Sp23.",".$Sp24.",".$Sp25.",".$Sp26;
			$herror{$keys}++; 
		}
		$total = $SpecsPerList[1] + $SpecsPerList[3]+ $SpecsPerList[5] +$SpecsPerList[7] +$SpecsPerList[9]+$SpecsPerList[11];
			
		if($total != 100 && $total != 0 )
		{
			$keys="Stotal perct !=100"."#$total#".$SpeciesComp2."#original percentages#".$Sp21Per.",".$Sp22Per.",".$Sp23Per.",".$Sp24Per.",".$Sp25Per.",".$Sp26Per;
			$herror{$keys}++; 
			#$errspec=1;
		}
		$SpeciesComp2 = $SpeciesComp2 .",XXXX UNDF,0,XXXX UNDF,0,XXXX UNDF,0,XXXX UNDF,0";

		#species layer3
		$errspec = 0;
		$SpeciesComp3 = Species_SFVI($Sp31,$Sp31Per,$Sp32,$Sp32Per,$Sp33,$Sp33Per,$Sp34,$Sp34Per,$Sp35,$Sp35Per,$Sp36,$Sp36Per,$spfreq);

		@SpecsPerList  = split(",", $SpeciesComp3); 
		for($cpt_ind=0; $cpt_ind<=5; $cpt_ind++)
		{  
			$posi=$cpt_ind*2;
		    if($SpecsPerList[$posi] eq SPECIES_ERRCODE ) 
			{ 
				$errspec=1;
			}
		}
		if($errspec == 1)
		{
			$keys="species layer 3".$SpeciesComp3."#original species#".$Sp31.",".$Sp32.",".$Sp33.",".$Sp34.",".$Sp35.",".$Sp36;
			$herror{$keys}++; 
		}
		$total = $SpecsPerList[1] + $SpecsPerList[3]+ $SpecsPerList[5] +$SpecsPerList[7] +$SpecsPerList[9]+$SpecsPerList[11];
			
		if($total != 100 && $total != 0 )
		{
			$keys="Stotal perct !=100"."#$total#".$SpeciesComp3."#original percentage#".$Sp31Per.",".$Sp32Per.",".$Sp33Per.",".$Sp34Per.",".$Sp35Per.",".$Sp36Per;
			$herror{$keys}++; 
			#$errspec=1;
		}
		$SpeciesComp3 = $SpeciesComp3 .",XXXX UNDF,0,XXXX UNDF,0,XXXX UNDF,0,XXXX UNDF,0";
		

		$OriginHigh1 = UpperOrigin($row->{L1_YOO});
		$OriginLow1 = LowerOrigin($row->{L1_YOO});
		if($OriginHigh1   eq ERRCODE   || $OriginLow1  eq ERRCODE ) 
		{ 
			if (isempty($row->{L1_SP1}) &&  ($row->{L1_YOO} eq "0" ||isempty($row->{L1_YOO})))
			{
				$OriginHigh1 = MISSCODE;
				$OriginLow1 = MISSCODE;
			}
			elsif ($row->{L1_YOO} ne "0" && !isempty($row->{L1_YOO}))
			{
				$keys="Origin1"."#".$row->{L1_YOO};
				$herror{$keys}++;
			}
		}
	 	if( ($OriginHigh1< $OriginLow1) || $OriginHigh1>2014 || ($OriginHigh1 <1700 && $OriginHigh1 >0) || ($OriginLow1 <1700 && $OriginLow1 >0) || $OriginLow1>2014) 
	 	{ 
			$keys="bounds for Origin1"."#".$row->{L1_YOO};
			$herror{$keys}++;
		}
		if( (($OriginHigh1>0) && length ($OriginHigh1) !=4 )  || (($OriginLow1>0) && length ($OriginLow1)!=4 ))
		{
			$keys="computed Origin"."#".$OriginHigh1."--".$OriginLow1;
			$herror{$keys}++;
		}

		$OriginHigh2 = UpperOrigin($row->{L2_YOO});
		$OriginLow2 = LowerOrigin($row->{L2_YOO});
		if($OriginHigh2   eq ERRCODE   || $OriginLow2  eq ERRCODE ) 
		{ 
			if (isempty($row->{L2_SP1}) &&  ($row->{L2_YOO} eq "0" ||isempty($row->{L2_YOO})))
			{
				$OriginHigh2 = MISSCODE;
				$OriginLow2 = MISSCODE;
			}
			elsif ($row->{L2_YOO} ne "0" && !isempty($row->{L2_YOO}))
			{
				$keys="Origin2"."#".$row->{L2_YOO};
				$herror{$keys}++;
			}
		}
	 	if( ($OriginHigh2< $OriginLow2) || $OriginHigh2>2014 || ($OriginHigh2 <1700 && $OriginHigh2 >0) || ($OriginLow2 <1700 && $OriginLow2 >0) || $OriginLow2>2014) 
	 	{ 
			$keys="bounds for Origin2"."#".$row->{L2_YOO};
			$herror{$keys}++;
		}
		if( (($OriginHigh2>0) && length ($OriginHigh2) !=4 )  || (($OriginLow2>0) && length ($OriginLow2)!=4 ))
		{
			$keys="computed Origin"."#".$OriginHigh2."--".$OriginLow2;
			$herror{$keys}++;
		}


		$OriginHigh3 = UpperOrigin($row->{L3_YOO});
		$OriginLow3 = LowerOrigin($row->{L3_YOO});
		if($OriginHigh3   eq ERRCODE   || $OriginLow3  eq ERRCODE ) 
		{ 
			if (isempty($row->{L3_SP1}) &&  ($row->{L3_YOO} eq "0" ||isempty($row->{L3_YOO})))
			{
				$OriginHigh3 = MISSCODE;
				$OriginLow3 = MISSCODE;
			}
			elsif ($row->{L3_YOO} ne "0" && !isempty($row->{L3_YOO}))
			{
				$keys="Origin3"."#".$row->{L3_YOO};
				$herror{$keys}++;
			}
		}
	 	if( ($OriginHigh3< $OriginLow3) || $OriginHigh3>2014 || ($OriginHigh3 <1700 && $OriginHigh3 >0) || ($OriginLow3 <1700 && $OriginLow3 >0) || $OriginLow3>2014) 
	 	{ 
			$keys="bounds for Origin3"."#".$row->{L3_YOO};
			$herror{$keys}++;
		}
		if( (($OriginHigh3>0) && length ($OriginHigh3) !=4 )  || (($OriginLow3>0) && length ($OriginLow3)!=4 ))
		{
			$keys="computed Origin"."#".$OriginHigh3."--".$OriginLow3;
			$herror{$keys}++;
		}

	 	$SiteClass = UNDEF; #"";
		$SiteIndex = UNDEF; #"";
		#$UnprodFor =UNDEF; #"";
		#@SpecsPerList  = split(",", $SpeciesComp);  
	    # ===== Non-forested Land =====
		$NatNonVeg = NaturallyNonVegetated($NVSL, $AQL);
		$NonForVeg = NonForested( $SHRUB1,$SHR_CC,$HERBS1,$HB_CC,$MoistReg,$CrownClosure1,$CrownClosure2,$CrownClosure3);  
		$UnProdFor = UNDEF;
		$NonVegAnth = NonVegetatedAnth($LUC, $AQL, $TRNSP);

		if(($NatNonVeg  eq ERRCODE) && ($NonVegAnth eq ERRCODE) && ($NonForVeg eq ERRCODE)) 
		{
			if(($NatNonVeg  eq ERRCODE) ) 
			{ 
				$keys="Natnonveg"."#nvsl and aql ==".$NVSL."--".$AQL;
				$herror{$keys}++;
			}
			if( ($NonVegAnth eq ERRCODE)) 
			{ 
				$keys="NonVegAnth"."#LUC, AQL and TRSNP = ".$LUC."--".$AQL."--".$TRNSP;
				$herror{$keys}++;
			}
			# if(($NonForVeg eq ERRCODE)) 
			# { 
			# 	if(!defined $SHRUB1)
			# 	{
			# 		$SHRUB1 = "#BK#";
			# 	}
			# 	if(!defined $HERBS1)
			# 	{
			# 		$HERBS1 = "#BK#";
			# 	}
			# 	if(!defined $SHR_CC)
			# 	{
			# 		$SHR_CC = "#BK#";
			# 	}
			# 	if(!defined $HB_CC)
			# 	{
			# 		$HB_CC = "#BK#";
			# 	}
			# 	$keys="NonForVeg"."##SHRUB1,SHR_CC,HERBS1,HB_CC,SMR,CC1,CC2,CC3".$SHRUB1."#".$SHR_CC."#".$HERBS1."#".$HB_CC."#".$MoistReg."#".$CrownClosure1."#".$CrownClosure2."#".$CrownClosure3;
			# 	$herror{$keys}++;
			# }
			# else 
		}
		# {
			if ($NatNonVeg  eq ERRCODE) { 
				$NatNonVeg = MISSCODE;  				
			}
		  	if ($NonForVeg  eq ERRCODE) { 
				$NonForVeg = MISSCODE;  				
			}
			if ($NonVegAnth  eq ERRCODE) { 
				$NonVegAnth = MISSCODE;  				
		 	}
		#}

		# ===== Modifiers ===== 
		#dist1
		$Dist1 = Disturbance($Mod1, $ModYr1);
		my ($Cd11, $Cd12)=split(",", $Dist1);
		if($Cd11 eq ERRCODE) 
		{ 
			$keys="disturbance1"."#".$Mod1;
			$herror{$keys}++;
		}

		my $Dist1ExtUp1 = DisturbanceExtUpper($Mod1Ext);
		my $Dist1ExtLo1 = DisturbanceExtLower($Mod1Ext);

		if($Dist1ExtUp1 eq ERRCODE || $Dist1ExtLo1 eq ERRCODE) 
		{ 
			$keys="disturbance1ExtentUpp1"."#".$Mod1Ext;
			$herror{$keys}++;
		}
		$Dist1 = $Dist1 .",".$Dist1ExtUp1 .",".$Dist1ExtLo1;

		#dist2
		$Dist2 = Disturbance($Mod2, $ModYr2);
		my ($Cd21, $Cd22)=split(",", $Dist2);
		if($Cd21 eq ERRCODE) 
		{ 
			$keys="disturbance2"."#".$Mod2;
			$herror{$keys}++;
		}

		my $Dist2ExtUp1 = DisturbanceExtUpper($Mod2Ext);
		my $Dist2ExtLo1 = DisturbanceExtLower($Mod2Ext);

		if($Dist2ExtUp1 eq ERRCODE || $Dist2ExtLo1 eq ERRCODE) 
		{ 
			$keys="disturbance2ExtentUpp1"."#".$Mod2Ext;
			$herror{$keys}++;
		}
		$Dist2 = $Dist2 .",".$Dist2ExtUp1 .",".$Dist2ExtLo1;

		#dist3
		$Dist3 = Disturbance($Mod3, $ModYr3);
		my ($Cd31, $Cd32)=split(",", $Dist3);
		if($Cd31 eq ERRCODE) 
		{ 
			$keys="disturbance3"."#".$Mod3;
			$herror{$keys}++;
		}

		my $Dist3ExtUp1 = DisturbanceExtUpper($Mod3Ext);
		my $Dist3ExtLo1 = DisturbanceExtLower($Mod3Ext);

		if($Dist3ExtUp1 eq ERRCODE || $Dist3ExtLo1 eq ERRCODE) 
		{ 
			$keys="disturbance3ExtentUpp1"."#".$Mod3Ext;
			$herror{$keys}++;
		}
		$Dist3 = $Dist3 .",".$Dist3ExtUp1 .",".$Dist3ExtLo1;

		# DISTURBANCE row
	    $Dist = $Dist1 . "," . $Dist2 . "," . $Dist3;


	    my $forested_poly = 0;
		my $ProdFor = "PF";
		
		# ($Sp31, @Spreste3) = split(",", $SpeciesComp3); 
		# ($Sp21, @Spreste2) = split(",", $SpeciesComp2); 
		# ($Sp11, @Spreste1) = split(",", $SpeciesComp1); 
		if (isempty($Sp11)) 
		{
			# if($UnProdFor ne MISSCODE && $UnProdFor ne ERRCODE && $UnProdFor ne UNDEF)
			# {
			# 	$forested_poly = 1;
			# 	$ProdFor = $UnProdFor;
			# }
			# els

			if($CCLow1 > 0  ||  $HeightLow1 > 0)
			{ 
				$ProdFor = "PP";
				$forested_poly = 1;
				$keys="null species, undef unprodfor,  with density or height, PRODUCTIVE_FOR will be set to PP";
				$herror{$keys}++; 
			}
			$SpeciesComp1 ="XXXX MISS,0,XXXX MISS,0,XXXX MISS,0,XXXX MISS,0,XXXX MISS,0,XXXX MISS,0,XXXX MISS,0,XXXX MISS,0,XXXX MISS,0,XXXX MISS,0";
		} 
		
		if($Cd11 eq "CO" || $Cd21 eq "CO" || $Cd31 eq "CO") 
		{ 
			$ProdFor = "PF";
			$forested_poly = 1;
		}      
	 
		# ===== Output inventory info for layer 1 =====
		#print ($StandStructureCode); exit;

		$StandStructureCode = StandStructure($row->{L1_LAYER_TYPE});

		if($StandStructureCode eq ERRCODE) 
		{ 
			$keys="structure"."#".$row->{L1_LAYER_TYPE};
			$herror{$keys}++;
		}
		my $numlayers = 1;
		if(!isempty( $row->{L2_LAYER_TYPE} ))
		{
			$numlayers = 2;
			if($StandStructureCode eq "S") 
			{ 
				$keys="casid = $CAS_ID, structure S with numlayers 2"."#layer2type=".$row->{L2_LAYER_TYPE};
				$herror{$keys}++;
			}
		}
		if(!isempty($row->{L3_LAYER_TYPE}))
		{
			$numlayers = 3;
			if($StandStructureCode eq "S") 
			{ 
				$keys="casid = $CAS_ID, structure S with numlayers 3"."#layer3type=".$row->{L3_LAYER_TYPE};
				$herror{$keys}++;
			}
		}
	  	

	  	$CAS_Record = $CAS_ID . "," . $PolyNum . "," . $StandStructureCode . ",$numlayers," . $IdentifyID . "," . $MapSheetID . "," . $Area . "," . $Perimeter . ",".$Area. ",".$PHOTO_YEAR;
		print CASCAS $CAS_Record . "\n";
	 	$nbpr=1;$$ncas++;$ncasprev++;

		   
	        #forested
			if (!isempty($Sp11) || $forested_poly == 1) 
		    {
		    	$LYR_Record1 = $row->{CAS_ID} . "," . $SMR  . "," . MISSCODE . ",1,1";
		      	$LYR_Record2 = $CCHigh1 . "," . $CCLow1 . "," . $HeightHigh1 . "," . $HeightLow1 . "," . $ProdFor.",". $SpeciesComp1;  # before speciescomp  . "," . $UnProdFor
		     	$LYR_Record3 = $OriginHigh1 . "," . $OriginLow1 . "," . $SiteClass . "," . $SiteIndex;
		      	$Lyr_Record = $LYR_Record1 . "," . $LYR_Record2 . "," . $LYR_Record3;
		      	print CASLYR $Lyr_Record . "\n";
			  	$nbpr++; $$nlyr++;$nlyrprev++;
		    }
	        #non-foested
		    elsif (!is_missing($NatNonVeg)  || !is_missing($NonForVeg) || !is_missing($NonVegAnth)) 
		    {
		   		#if ($UnProdFor ne MISSCODE || $NonForVeg ne MISSCODE || $UnProdFor ne MISSCODE) {
		      	$NFL_Record1 = $row->{CAS_ID}. "," . $SMR  . "," . MISSCODE . ",1,1";
		      	$NFL_Record2 = $CCHigh1 . "," . $CCLow1 . "," . $HeightHigh1 . "," . $HeightLow1;
	            $NFL_Record3 = $NatNonVeg . "," . $NonForVeg . "," . $NonVegAnth;  #	$UnProdFor;
	            $NFL_Record = $NFL_Record1 . "," . $NFL_Record2 . "," . $NFL_Record3;
		      	print CASNFL $NFL_Record . "\n";
				$nbpr++;$$nnfl++;$nnflprev++;
		    }
			#new to avoid dropped records - 19-09-2012
		  	elsif($row->{TYPE} eq "OP") # previous field was MLEVEL
		  	{
		      	$NFL_Record1 = $row->{CAS_ID}. "," . $SMR  . "," . MISSCODE . ",1,1";
		      	$NFL_Record2 = $CCHigh1 . "," . $CCLow1 . "," . $HeightHigh1 . "," . $HeightLow1;
	            $NFL_Record3 = $NatNonVeg . "," . "OT" . "," . $NonVegAnth;   #previous UK NatNonveg code was there corrected by OT on 28 feb 2013
	            $NFL_Record = $NFL_Record1 . "," . $NFL_Record2 . "," . $NFL_Record3;
		      	print CASNFL $NFL_Record . "\n";
				$nbpr++;$$nnfl++;$nnflprev++;
		  	}
	 		elsif(isempty($row->{TYPE}))  # previous field was MLEVEL
	 		{

		      	$NFL_Record1 = $row->{CAS_ID}. "," . $SMR  . "," . MISSCODE . ",1,1";
		      	$NFL_Record2 = $CCHigh1 . "," . $CCLow1 . "," . $HeightHigh1 . "," . $HeightLow1;
	            $NFL_Record3 = $NatNonVeg . "," . "ST" . "," . $NonVegAnth;  #	$UnProdFor;
	            $NFL_Record = $NFL_Record1 . "," . $NFL_Record2 . "," . $NFL_Record3;
		      	print CASNFL $NFL_Record . "\n";
				$nbpr++;$$nnfl++;$nnflprev++;
		  	}
	        #Disturbance
		    if (!isempty($row->{DISTURBANCE_1})) 
		    {
		      	$DST_Record = $row->{CAS_ID} . "," . $Dist. ",1";
		      	print CASDST $DST_Record . "\n";
				if($nbpr==1) {$$ndstonly++; $ndstonlyprev++;}
				$nbpr++;$$ndst++;$ndstprev++;
		    }
		   	elsif ($row->{TYPE} eq "SIL" ||  $row->{TYPE} eq "EXP")  # previous field was MLEVEL
		   	{

	 	      	$Dist = "CO,-8888,-8888,-8888" . "," . $Dist2 . "," . $Dist3;
		      	$DST_Record = $row->{CAS_ID} . "," . $Dist. ",1";
		      	print CASDST $DST_Record . "\n";
				if($nbpr==1) {$$ndstonly++; $ndstonlyprev++;}
				$nbpr++;$$ndst++;$ndstprev++;
		    }
		    #Ecological 
		    if ($Wetland ne MISSCODE) 
		    {
		      	$Wetland = $row->{CAS_ID} . "," . $Wetland."-";
		      	print CASECO $Wetland . "\n";
				if($nbpr==1) {$$necoonly++;$necoonlyprev++;}
				$nbpr++;$$neco++;$necoprev++;
		    }

		if (($StandStructureCode eq "M"))
		{
	        if (!isempty($Sp21)) # || $forested_poly == 1
		    {
		    	$LYR_Record1 = $row->{CAS_ID} . "," . $SMR  . "," . MISSCODE . ",2,1";
		      	$LYR_Record2 = $CCHigh2 . "," . $CCLow2 . "," . $HeightHigh2 . "," . $HeightLow2 . "," . $ProdFor.",". $SpeciesComp2;  # before speciescomp  . "," . $UnProdFor
		     	$LYR_Record3 = $OriginHigh2 . "," . $OriginLow2 . "," . $SiteClass . "," . $SiteIndex;
		      	$Lyr_Record = $LYR_Record1 . "," . $LYR_Record2 . "," . $LYR_Record3;
		      	print CASLYR $Lyr_Record . "\n";
			  	$nbpr++; $$nlyr++;$nlyrprev++;
		    }

		    if ($numlayers==3 && (!isempty($Sp31) )) #|| $forested_poly == 1 
		    {
		    	$LYR_Record1 = $row->{CAS_ID} . "," . $SMR  . "," . MISSCODE . ",3,1";
		      	$LYR_Record2 = $CCHigh3 . "," . $CCLow3 . "," . $HeightHigh3 . "," . $HeightLow3 . "," . $ProdFor.",". $SpeciesComp3;  # before speciescomp  . "," . $UnProdFor
		     	$LYR_Record3 = $OriginHigh3 . "," . $OriginLow3 . "," . $SiteClass . "," . $SiteIndex;
		      	$Lyr_Record = $LYR_Record1 . "," . $LYR_Record2 . "," . $LYR_Record3;
		      	print CASLYR $Lyr_Record . "\n";
			  	$nbpr++; $$nlyr++;$nlyrprev++;
		    }
		}

		if($nbpr ==1 || $nbpr ==0)
		{
			if(isempty($row->{L1_SP1}) && $forested_poly == 0  && isempty($row->{DISTURBANCE_1})  &&  isempty($row->{TYPE}) && $Wetland eq MISSCODE) 
			{	
				$keys = "WILL PROBABLY DROP THIS>>>code for wetland DRAIN+=";
			}
			elsif(isempty($row->{L1_SP1}) && $forested_poly == 0 && isempty($row->{DISTURBANCE_1}) && isempty($row->{TYPE})) 
			{
				$keys = "WILL DROP instead of wetland";
	 			$herror{$keys}++; 
			}
			elsif(isempty($row->{L1_SP1})  && $forested_poly == 0 && isempty($row->{DISTURBANCE_1}) ) #&& $row->{TYPE} eq "0"
			{
				$keys = "WILL DROP  TYPE == $row->{TYPE}";
	 			$herror{$keys}++; 
			}
			elsif(isempty($row->{L1_SP1}) && $forested_poly == 0) {
				$keys = "WILL DROP instead nfl and dist-TYPE="."-distcode=".$row->{DISTURANCE_1};
	 			$herror{$keys}++; 
			}
			else 
			{
				$keys ="!!! record may be dropped#".$CAS_ID."bcse>>>specs=".$row->{L1_SP1}."-distcode=".$row->{DISTURANCE_1}."-NPcode=".$row->{TYPE}."-wetcode=";
	 			$herror{$keys}++; 
				$keys ="#droppable#";
	 			$herror{$keys}++; 
			}
		}
	}
 	$csv->eof or $csv->error_diag ();
  	close $SKinv;

	foreach my $k (sort {lc($a) cmp lc($b)} keys %$spfreq)
	{
		$_ = $k;
		tr/a-z/A-Z/;
		my $upk = $_;
	 	print SPERRSFILE "cumulative frequency of species " ,$upk,  " is ", $spfreq->{$k},"\n";
		#print "invalid code " ,$k,  " found ", $herror{$k}," times\n";
  	}
	foreach my $k (keys %herror)
	{
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
	print " for this file, #records in casfile : $ncasprev, lyrfile : $nlyrprev, nflfile : $nnflprev,  dstfile : $ndstprev($ndstonlyprev), ecofile : $necoprev($necoonlyprev)--- total (without .cas): $total($total2)\n";
}


1;
#province eq "SK";

