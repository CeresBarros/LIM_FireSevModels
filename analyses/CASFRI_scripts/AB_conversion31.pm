package  ModulesV4::AB_conversion31;

use Exporter;
use feature ":5.10"; 

our @ISA = qw(Exporter);
our @EXPORT = qw(&ABinv_to_CAS );
#our @EXPORT_OK = qw(%spfreq);
our $hdr_num;
#our %spfreq;
our $nbas=0;
our $Species_table;	
# our is a global variable that the main script will call
#our @EXPORT_OK = qw(@tabSpec &SoilMoistureRegime1 &SoilMoistureRegime2  &CCUpper  &CCLower &StandHeightUp &StandHeightLow &UpperOrigin &UpperOriginCompl &LowerOrigin &LowerOriginCompl  &Disturbance &DisturbanceM );

use strict;
use Text::CSV;

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
		
	if(!defined ($val) || $val eq MISSCODE || $val eq ERRCODE || $val eq UNDEF) 
	{
		return 1;
	}
	else 
	{
		return 0;
	}	
}
# Inventory version
# 1 : Phase 3
# 2 : AVI 2.1
# 3 : AVI 2.1 +
# 4 : AVI 2.1 other
# default
our $IV = 2;

#Determine SoilMoistureRegime from MoistReg value
# field name : SMR
sub SoilMoistureRegime 
{

	my $MoistReg = shift(@_); 
	my $Sp1 = shift(@_); 

	sub isWet
	{
		my $specie = $_[0];
		my $code;
		
		$specie = Latine($specie);
		if($specie eq "Lari lari" || $specie eq "Pice mari")
		{
			$code = "W";
		}	
		else
		{
			$code = "M"
		}
		return $code;
	}
	
	# version 2.1
	my %MoistRegHash;
	given ($IV) {

		# todo voir le traitement de AVI 2.1 other
		when (1) 	{    # version Phase 3
			#todo confirmer le traitement de phase 3
			return MISSCODE;
		}
		when (2) 	{    # version AVI 2.1
			%MoistRegHash = (
				""  => MISSCODE,
				0 	=> -1, # special case (look at overstory)
				"N" => isWet($Sp1),
				"D" => "D",
				"U" => isWet($Sp1),
				"M" => "F",
				"W" => "W",
				"A" => "A"
			);
		}
		when ([3,4]) 	{    # version AVI 2.1 +
			%MoistRegHash = (
				"" => MISSCODE,
				0  => "D",
				1  => "D",
				2  => "D",
				3  => "F",
				4  => "F",
				5  => "M",
				6  => "W",
				7  => "W",
				8  => "A"
			);
		}
	}
	my $SoilMoistureReg;

	# get new value
	if ( isempty($MoistReg)) { $SoilMoistureReg = MISSCODE; }
	else 
	{
		$MoistReg = uc($MoistReg);
		if ( !$MoistRegHash{$MoistReg} ) { $SoilMoistureReg = ERRCODE; }
		else { $SoilMoistureReg = $MoistRegHash{$MoistReg}; }
	}

	return $SoilMoistureReg;
}

#Determine StandStructure from Struc value
#  field name : STAND_STRUCTURE
sub StandStructure 
{
	# todo confirm that the versions are handled the same
	my $Struc = shift(@_); 
	my %StrucHash = (
		""  => "S",
		0	=> "S",
		"S" => "S",
		"C" => "C",
		"H" => "H",
		"M" => "M"
	);

	my $StandStructure;

	if ( isempty($Struc)) { $StandStructure = MISSCODE; }
	else 
	{
		$Struc = uc($Struc);
		if ( !$StrucHash{$Struc} ) { $StandStructure = ERRCODE; }
		else { $StandStructure = $StrucHash{$Struc}; }
	}
	
	return $StandStructure;
}

#Determine StandStructure from StrucVal
#  field name : STAND_STRUCTURE_PER
sub StandStructureValue 
{

	my $StrucVal;
	my $StandStructureValue;

	($StrucVal) = shift(@_);
	if ( isempty($StrucVal) ) 
	{
		$StandStructureValue = 0;
	}
	elsif ( ( $StrucVal < 1 ) || ( $StrucVal > 9 ) ) 
	{
		$StandStructureValue = 0;
	}
	elsif ( ( $StrucVal > 0 ) && ( $StrucVal < 10 ) ) 
	{
		$StandStructureValue = $StrucVal;
	}

	return $StandStructureValue;
}

#Determine CCUpper from Density
#  field name : CROWN_CLOSURE_UPPER
sub CCUpper 
{
	my $Density = shift(@_); 
	my $CCHigh;
	my %DensityList;

	if ( isempty($Density)) 
	{
		return MISSCODE;
	}

	given ($IV) {
		when ( [ 1, 2 ] ) {    # Phase 3 and AVI 2.1
			%DensityList = (
				0	=> MISSCODE,
				""  => MISSCODE,
				"A" => 30,
				"B" => 50,
				"C" => 70,
				"D" => 100
			);

			# raise code to upper case
			$Density = uc($Density);
		}
		when (3) {             # AVI 2.1 +
			if ( $Density ge 1 and $Density le 100 ) {
				return $Density;
			}
			else {
				if(isempty($Density)){
					return MISSCODE;
				}else{
					return ERRCODE;
				}
			}
		}
		when (4) {             # AVI 2.1 other
			%DensityList = (
				"V" => 100, # according to John
				"" => MISSCODE,
				0  => 10,
				1  => 20,
				2  => 30,
				3  => 40,
				4  => 50,
				5  => 60,
				6  => 70,
				7  => 80,
				8  => 90,
				9  => 100
			);
		}
	}

	$Density = uc($Density);
	if (!$DensityList{$Density}) 
	{
		$CCHigh = ERRCODE;
	}
	else 
	{
		$CCHigh = $DensityList{$Density};
	}

	return $CCHigh;
}

#Determine CCLower from Density
#  field name : CROWN_CLOSURE_LOWER
sub CCLower 
{
	my $CCLow;
	my $Density = shift(@_); 
	my %DensityList;

	if ( isempty($Density)) 
	{
		return MISSCODE;
	}


	given ($IV) {
		when ( [ 1, 2 ] ) {    # Phase 3 and AVI 2.1
			%DensityList = (
				0	=> MISSCODE,
				""  => MISSCODE,
				"A" => 6,
				"B" => 31,
				"C" => 51,
				"D" => 71
			);

			# raise code to upper case
			$Density = uc($Density);
		}
		when (3) {             # AVI 2.1 +
			if ( $Density ge 1 and $Density le 100 ) {
				return $Density;
			}
			else {
				if(isempty($Density)){
					return MISSCODE;
				}else{
					return ERRCODE;
				}
			}
		}
		when (4) {             # AVI 2.1 other
			%DensityList = (
				"V" => 71, # according to John
				"" =>MISSCODE,
				0  => 6,
				1  => 11,
				2  => 21,
				3  => 31,
				4  => 41,
				5  => 51,
				6  => 61,
				7  => 71,
				8  => 81,
				9  => 91
			);
		}
	}

	$Density = uc($Density);
	if ( !$DensityList{$Density} ) 
	{
		$CCLow = ERRCODE;
	}
	else 
	{
		$CCLow = $DensityList{$Density};
	}

	return $CCLow;
}

#Determine stand height from Height
sub StandHeight 
{
	my $Height;

	($Height) = shift(@_);
	if ( isempty($Height)) { $Height = MISSCODE; }
	elsif ( ( $Height <= 0 ) || ( $Height > 50 ) ) { $Height = MISSCODE; }
	elsif ( ( $Height > 0 ) && ( $Height <= 50 ) ) { $Height = $Height; }
	else{$Height = ERRCODE; }
	# todo manage errors
	return $Height;
}

#Determine lower bound stand height from Height
#  field name : HEIGHT_LOWER
sub SHLower 
{
	my $SHLow;
	my $Height = shift(@_); 
	my %HeightHash;

	if(isempty($Height))
	{
		return MISSCODE;
	}
	given ($IV) {
		when (1) {    # Phase 3
			%HeightHash = (
				"" => MISSCODE,    # task if string empty mean missing or error
				0  => 0,
				1  => 6.1,
				2  => 12.1,
				3  => 18.1,
				4  => 24.1,
				5  => 30.1
			);

			if ( isempty($Height)) {
				$SHLow = MISSCODE;
			}
			elsif ( !$HeightHash{$Height} ) {
				$SHLow = ERRCODE;
			}
			else {
				$SHLow = $HeightHash{$Height};
			}
			return $SHLow;
		}
		when ( [ 2, 3, 4 ] ) {    # AVI 2.1, AVI 2.1 +, AVI 2.1 other
			if ( $Height ge 0.5 ) {
				return $Height - 0.5;
			}
			elsif ( isempty($Height)) {
				return MISSCODE;
			}
			elsif($Height = 0){
				return 0;
			}
			else {
				return ERRCODE;
			}
		}
	}

	# just in case
	return ERRCODE;

}

#Determine upper bound stand height from Height
#  field name : HEIGHT_UPPER
sub SHUpper {
	my $SHHigh;
	my $Height = shift(@_); 
	my %HeightHash;

	if(isempty($Height))
	{
		return MISSCODE;
	}
	given ($IV) {
		when (1) {    # Phase 3
			%HeightHash = (
				"" => MISSCODE,
				0  => 6.0,
				1  => 12.0,
				2  => 18.0,
				3  => 24.0,
				4  => 30.0,
				5  => INFTY
			);

			if ( isempty($Height)) {
				$SHHigh = MISSCODE;
			}
			elsif ( !$HeightHash{$Height} ) {
				$SHHigh = ERRCODE;
			}
			else {
				$SHHigh = $HeightHash{$Height};
			}
			return $SHHigh;
		}
		when ( [ 2, 3, 4 ] ) {    # AVI 2.1, AVI 2.1 +, AVI 2.1 other
			if ( $Height ge 0 ) {
				return $Height + 0.5;
			}
			elsif ( isempty($Height)) {
				return MISSCODE;
			}
			elsif($Height = 0){
				return 0;
			}
			else {
				return ERRCODE;
			}
		}
	}

	# just in case
	return ERRCODE;
}

# task ask for the species tables

#Determine Latine name of species
sub Latine 
{
	my $CurrentSpecies = shift(@_);
	my $GenusSpecies;

	if (isempty($CurrentSpecies))   { $GenusSpecies = "XXXX MISS"; }
	else 
	{
		$_ = $CurrentSpecies;
		tr/a-z/A-Z/;
		$CurrentSpecies = $_;

		if ($Species_table->{$CurrentSpecies}) { $GenusSpecies = $Species_table->{$CurrentSpecies}; }
		else 	 
		{
			print SPECSLOGFILE "Illegal species code $CurrentSpecies,CAS_ID= $Glob_CASID,file=$Glob_filename\n"; $GenusSpecies = SPECIES_ERRCODE; 
		} 
	}
	return $GenusSpecies;
}


#Determine Species from the 5 Species fields
sub Species 
{

	my $Sp1    = shift(@_);
	my $Sp1Per = shift(@_);
	my $Sp2    = shift(@_);
	my $Sp2Per = shift(@_);
	my $Sp3    = shift(@_);
	my $Sp3Per = shift(@_);
	my $Sp4    = shift(@_);
	my $Sp4Per = shift(@_);

	# cut here for Phase 3 (only 4 sp)
	my $Sp5    = shift(@_);
	my $Sp5Per = shift(@_);
	my $spfreq=shift(@_);
	
	my $Species;
	my $CurrentSpec;

	my $spper1;my $spper2;my $spper3;my $spper4;my $spper5;

	if (isempty($Sp1)) { $Sp1 = ""; }
	if (isempty($Sp2)) { $Sp2 = ""; }
	if (isempty($Sp3)) { $Sp3 = ""; }
	if (isempty($Sp4)) { $Sp4 = ""; }
	if (isempty($Sp5)) { $Sp5 = ""; }

	given ($IV) {
		
		when ( [ 2, 3, 4 ] ) {    # AVI 2.1, AVI 2.1 +, AVI 2.1 other
					if ( isempty($Sp1Per)) { $spper1 = 0; }
					else { $spper1 = $Sp1Per * 10; }

					if ( isempty($Sp2Per)) { $spper2 = 0; }
					else { $spper2 = $Sp2Per * 10; }

					if ( isempty($Sp3Per)) { $spper3 = 0; }
					else { $spper3 = $Sp3Per * 10; }
	
					if ( isempty($Sp4Per)) { $spper4 = 0; }
					else { $spper4 = $Sp4Per * 10; }

					if ( isempty($Sp5Per)) { $spper5 = 0; }
					else { $spper5 = $Sp5Per * 10; }
		}
		when (1) {    # Phase 3

					$spper1=0;$spper2=0;$spper3=0;$spper4=0;$spper5=0;
					if(!isempty($Sp1) && isempty($Sp2) && isempty($Sp3) && isempty($Sp4) && isempty($Sp5)) {$spper1=100;}
					elsif(!isempty($Sp1) && !isempty($Sp2) && isempty($Sp3)  && isempty($Sp4)  && isempty($Sp5)) {$spper1=65;$spper2=35;}
					elsif(!isempty($Sp1) && isempty($Sp2)  && isempty($Sp3)  && !isempty($Sp4) && isempty($Sp5)) {$spper1=85;$spper4=15;}
					elsif(!isempty($Sp1) && !isempty($Sp2) && !isempty($Sp3) && isempty($Sp4)  && isempty($Sp5)) {$spper1=43;$spper2=30;$spper3=27;}
					elsif(!isempty($Sp1) && !isempty($Sp2) && isempty($Sp3)  && !isempty($Sp4) && isempty($Sp5)) {$spper1=55;$spper2=30;$spper4=15;}
					elsif(!isempty($Sp1) && isempty($Sp2)  && !isempty($Sp3) && !isempty($Sp4) && isempty($Sp5)) {$spper1=75;$spper3=15;$spper4=10;}
					elsif(!isempty($Sp1) && !isempty($Sp2) && !isempty($Sp3) && !isempty($Sp4) && isempty($Sp5)) {$spper1=40;$spper2=35;$spper3=15;$spper4=10;}
		}
	}

	$spfreq->{$Sp1}++;
	$spfreq->{$Sp2}++;
	$spfreq->{$Sp3}++;
	$spfreq->{$Sp4}++;
	$spfreq->{$Sp5}++;

	$Sp1 = Latine($Sp1);
	$Sp2 = Latine($Sp2);
	$Sp3 = Latine($Sp3);
	$Sp4 = Latine($Sp4);
	$Sp5 = Latine($Sp5);

	my $total=$spper1+$spper2+$spper3+$spper4+$spper5;
	
	$Species =
	    $Sp1 . "," . $spper1 . "," . $Sp2 . "," . $spper2 . "," . $Sp3 . ","
	  . $spper3 . ","
	  . $Sp4 . ","
	  . $spper4 . ","
	  . $Sp5 . ","
	  . $spper5;

	return $Species;
}

#Determine upper stand origin from Origin
#  field name : ORIGIN_UPPER
sub OriginUpper 
{
	my $Origin;
	my $thousand = "1";
		
	($Origin) = shift(@_);

	if(isempty($Origin))
	{
		return MISSCODE;
	}

	#print "read  $Origin\n";
	$Origin =~ s/\.([0-9]+)$//g;
	# remove decimal (0)
	#if ( $Origin =~ m/^([0-9]{1-4}).0$/ ) {
		#$Origin = $1;

	#print "now is $Origin\n";
	#}
	
		
	# 4 digits (doesn't handle years > 1999)
	#if ( $Origin =~ m/^[0-9]{4}$/ ) {
	if ( length($Origin) ==4 ) {	
		# if 
		#if ( $Origin =~ m/^2$/) {
			#$thousand = "2";	
		#}
		
		# check if need to convert to 2 digits
		#if ( $Origin le 1940 || $Origin =~ m/[0]$/) {
			# extract two central digits
			#$Origin =~ m/^[1-2]([0-9]{2})[0-9]$/;
			#$Origin = $1;
		#}
	}

	# two digits
	# set upper limit

	#if ( $Origin =~ m/^[0-9]{2}$/ ) {
	elsif ( length($Origin) == 2 ) {		
		$Origin = $thousand . $Origin . "9";
	}elsif($Origin eq "0" || $Origin eq ""){
		$Origin = MISSCODE;
	}
	elsif(!($Origin =~ m/^[0-9]{4}$/ )){
		$Origin = ERRCODE;
	}

#print "result is $Origin\n";
	return $Origin;
}

#Determine lower stand origin from Origin
#  field name : ORIGIN_LOWER
sub OriginLower 
{
	my $Origin;
	my $thousand = "1";
		
	($Origin) = shift(@_);
	if(isempty($Origin))
	{
		return MISSCODE;
	}

	
	# remove decimal (0)
	$Origin =~ s/\.([0-9]+)$//g;
	
		
	# 4 digits (doesn't handle years > 1999)
	#if ( $Origin =~ m/^[0-9]{4}$/ ) {
	if ( length($Origin) ==4 ) {		
		# if 
		#if ( $Origin =~ m/^2/) {
			#$thousand = "2";	
		#}
		
		# check if need to convert to 2 digits
		# conversion is made if year is rounded (ends with 0)
		#if ( $Origin le 1940 || $Origin =~ m/[0]$/) {
			# extract two central digits
			#$Origin =~ m/^[1-2]([0-9]{2})[0-9]$/;
			#$Origin = $1;
		#}
	}

	# two digits
	# set upper limit

	elsif ( $Origin =~ m/^[0-9]{2}$/ ) {
		
		$Origin = $thousand . $Origin . "0";
	}
	elsif($Origin eq "0" || $Origin eq ""){
		$Origin = MISSCODE;
	}
	elsif(!($Origin =~ m/^[0-9]{4}$/ )){
		$Origin = ERRCODE;
	}
#print "result lower is $Origin\n";
	return $Origin;
}

#Determine Site from TPR
#  field name : SITE_CLASS
sub Site 
{
	my $Site;
	my $TPR     = shift(@_);
	my %TPRHash = (
		""  => MISSCODE,
		0	=> MISSCODE,
		"U" => "U",
		"F" => "P",
		"M" => "M",
		"G" => "G"
	);

	# todo check if this block is consistent with other similar
	if ( isempty($TPR)) 
	{
		$Site = MISSCODE;
	}
	else
	{
		$TPR = uc($TPR);
		if ( !$TPRHash{$TPR} ) 
		{
			$Site = ERRCODE;
		}
		else 
		{
			$Site = $TPRHash{$TPR};
		}
	}

	return $Site;
}

#Determine Naturally non-vegetated stands (p.17 and p. 65-68)
#  field name : NATURALLY_NON_VEG
#Natnonveg ==== AP, LA, RI, OC, RK, SA, SI, SL, EX, BE, WS, FL, IS, TF
sub NaturallyNonVeg 
{

	# For AVI 2.1 and 2.1 + (probably AVI 2.1 other)
	# task check to which inventory AVI 2.1 other is tied by default.
	my $NatNonVeg = shift(@_); 
	my %NatNonVegList;

	if ( isempty($NatNonVeg)) 
	{
		return MISSCODE;
	}

	given ($IV) {
		when (1) {    # 1 : Phase 3
			%NatNonVegList = (
				""            => MISSCODE,
				0	=> MISSCODE,
				"W"           => "LA",
				"FL"          => "FL",
				"SAND"        => "SA",
				"CUT BANK"    => "EX",
				"ROCK BARREN" => "RK",
				"SOIL BARREN" => "EX",
			);
		}
		when ( [ 2, 3, 4 ] ) {    # 2 : AVI 2.1, AVI 2.1 +, AVI 2.1 other
			%NatNonVegList = (
				""    => MISSCODE,
				0	=> MISSCODE,
				"NMB" => "EX",
				"NMC" => "EX",
				"NMR" => "RK",
				"NMS" => "WS",
				"NWI" => "SI",
				"NWL" => "LA",
				"NWR" => "RI",
				"NWF" => "FL",
								
				"MB" => "EX",
				"MC" => "EX",
				"MR" => "RK",
				"MS" => "WS",
				"WI" => "SI",
				"WL" => "LA",
				"WR" => "RI",
				"WF" => "FL",
				"MG" => "SA",
				"NMM" => "RK",
				"MM" => "RK",
			);
		}
	}
	#"NMG" => "SA", #or SD?  VERIFY THIS

	$NatNonVeg = uc($NatNonVeg);	
	if ( $NatNonVegList{$NatNonVeg} ) 
	{
		$NatNonVeg = $NatNonVegList{$NatNonVeg};
	}
	else 
	{
		$NatNonVeg = ERRCODE;
	}

	return $NatNonVeg;
}

#Determine Non-forested anthropological stands
#  field name : NON_FOREST_ANTHRO
#Anthropogenic IN, FA, CL, SE, LG, BP, OT
sub NonForestedAnth 
{
	my $NonForAnth = shift(@_); 
	my %NonForAnthList;

	if ( isempty($NonForAnth)) 
	{
		return MISSCODE;
	}

	given ($IV) {
		when (1) {    # Phase 3
			return MISSCODE;
		}
		when ( [ 2, 3, 4 ] ) {    # AVI 2.1, AVI 2.1 +, AVI 2.1 other
			%NonForAnthList = (
				""    => MISSCODE,
				0	=> MISSCODE,
				"CIP" => "FA",
				"CIW" => "FA",
				"CA"  => "CL",
				"CP"  => "CL",
				"CPR" => "CL",
				"ASC" => "SE",
				"ASR" => "SE",
				"AII" => "IN",
				"AIM" => "IN",
				"AIF" => "SE",
				"AIG" => "IN",
				"AIE" => "IN",
				"AIH" => "FA",
				
				"IP" => "FA",
				"IW" => "FA",
				"A"  => "CL",
				"P"  => "CL",
				"PR" => "CL",
				"SC" => "SE",
				"SR" => "SE",
				"II" => "IN",
				"IM" => "IN",
				"IF" => "SE",
				"IG" => "IN",
				"IE" => "IN",
				"IH" => "FA",
					# add >
				"CIU" => "OT",
				"AIW" => "FA",
				"IW" => "FA",
				"AIU" => "OT",
				"IU" => "OT",
				"AIL" => "OT",

				# /add
			);
		}
	}

	if ( !$NonForAnthList{$NonForAnth} )
	{
		$NonForAnth = ERRCODE;
	}
	else 
	{
		$NonForAnth = $NonForAnthList{$NonForAnth};
	}

	return $NonForAnth;
}

#Determine Non-forested vegetation stands
#  field name : NON_FORESTED_VEG
#NonForestedVeg ---ST, SL, HF, HE, HG, BR, OM, BT
sub NonForestedVeg 
{
	my $NonForVeg    = shift(@_);
	my $NonForVegHgt = shift(@_);
	my $AnthVeg = shift(@_);
	my $NonForestedVeg;
	my %NonForVegList;

	if (isempty($NonForVeg)) 
	{
		return MISSCODE;
	}

	if(!isempty($AnthVeg) && ($AnthVeg eq "AIL")) {

		$NonForVeg = $AnthVeg;
	}
	$NonForVeg = uc($NonForVeg);

	sub SH 
	{
		my $HT  = shift(@_);
		my $SHU = SHUpper($HT);

		if ( ( $SHU eq MISSCODE ) || ( $SHU eq ERRCODE ) ) {
			$SHU = ERRCODE;
		}
		elsif ( $HT < 2 ) {
			$SHU = "SL"    #low
		}
		else {
			$SHU = "ST"    # default is tall shrub
		}
		return $SHU;
	}

	given ($IV) {
		when (1) {         # Phase 3
			%NonForVegList = (
				""          => MISSCODE,
				0			=> MISSCODE,
				"MUSKEG"    => "OM",
				"GRASSLAND" => "HG"
			);
		}
		when ( [ 2, 3, 4 ] ) {    # All AVI
			my $SOSC = SH($NonForVegHgt);
			%NonForVegList = (
				""  	=> MISSCODE,
				0		=> MISSCODE,
				"HG"	=> "HG",
				"BR"	=> "BR",
				"HF"	=> "HF",
				"SO"	=> $SOSC,
				"SC"	=> $SOSC,
				"AIL"	=> "HG",
				"IL" 	=> "HG",
				# guess from John Cosco
				"AS" => "SL"
			);

		}
	}
	
	
	if ( !$NonForVegList{$NonForVeg} ) 
	{
		$NonForestedVeg = ERRCODE;
	}
	else 
	{
		$NonForestedVeg = $NonForVegList{$NonForVeg};
	}
	
	return $NonForestedVeg;
}

# Determine Unproductive forest code
# field name : UNPRODUCTIVE_FOREST
#UnProdForest TM,TR, AL, SD, SC, NP
sub UnproductiveForest 
{
	my $unprodIn = shift(@_); 
	$unprodIn = uc($unprodIn);

	if ( $IV eq 1 ) 
	{

		# this is Phase 3
		my %unprodDict = (
			""                 => MISSCODE,
			0				   => MISSCODE,
			"TREED MUSKEG"     => "TM",
			"SCRUB CONIFEROUS" => "SC",
			"SCRUB DECIDUOUS"  => "SD"
		);

		if ( isempty($unprodIn) ) {
			return MISSCODE;
		}
		elsif ( !$unprodDict{$unprodIn} ) {
			return ERRCODE;
		}
		else {
			return $unprodDict{$unprodIn};
		}
	}
	else {    # AVI
			return UNDEF;
	}
}

#Determine Disturbance from Modifiers
#  field name : DISTn, DISTn_YEAR
#valid list CO,PC,BU, WF, DI, IK, FL,WE, SL,OT, DT,SI, UK

#note from SGC: GR is a treatment where the stand is developed for "grazing domestic livestock (cattle)"; formally we could call this SI, but that is misleading   
#It's not clear what is best here, I would go with "PC"  because typically these stands would have an open canopy of aspen with grasses on the surface, for the cows to eat
# cu BECOMES ILLEGAL --"CU" => "CL",
sub Disturbance
 {
	my $Mod;
	my $ModYr;
	my $DisturbanceCode;
	my %DistList;
	my $DisturbanceOut;
	my $DistYr;

	($Mod)   = shift(@_);
	($ModYr) = shift(@_);

	if(isempty($Mod))
	{
		$Mod = "";
	}	
	if(isempty($ModYr))
	{
		$ModYr = "";
	}	

	$Mod = uc($Mod);

	given ($IV) {
		when (1) {    # 1 : Phase 3
			%DistList = (
				""  => MISSCODE,
				0	=> MISSCODE,
				"V" => "OT",
				"W" => "WF",
				"X" => "CO",
				"CC" => "CO",
				"BU" => "BU",
				"FL" => "FL",
				"CC" => "CO",
				"Y" => "BU"
			);
		}
		when ( [ 2, 3, 4 ] ) {   # 2 : AVI 2.1, 3 : AVI 2.1 +, 4 : AVI 2.1 other
			%DistList = (
				""   => MISSCODE,
				0	=> MISSCODE,
				"ST" => "OT", # scattered trees -translated by SC
				"CC" => "CO",
				"BU" => "BU",
				"WF" => "WF",
				"DI" => "DI",
				"IK" => "IK",
				"UK" => "OT",
				"WE" => "WE",
				"DT" => "DT",
				"BT" => "OT",
				"FL" => "FL",
				"GR" => "PC",
				"PL" => "SI",
				"SI" => "SI",
				"SN" => "DT",
				"TH" => "SI",
				"SC" => "SI",
				"MT" => "OT",
				"FT" => "OT",
				"CL" => "OT"
			);
		}
	}

	if (is_missing($Mod))
	{
		return UNDEF.",".UNDEF;
	}
	if ( isempty($Mod)) {
		$DisturbanceCode = MISSCODE;
		$DistYr = DistYear($ModYr);
	}
	elsif ( !$DistList{$Mod} ) {
		$DisturbanceCode = ERRCODE;
		#$DistYr      = ERRCODE;
		$DistYr = DistYear($ModYr);
	}
	else {
		$DisturbanceCode = $DistList{$Mod};

		if ( $DisturbanceCode eq MISSCODE ) {
			#$DistYr = MISSCODE;
			$DistYr = DistYear($ModYr);
		}
		else {
			$DistYr = DistYear($ModYr);
		}
	}

	$DisturbanceOut = $DisturbanceCode . "," . $DistYr;
#print "result is $DisturbanceOut ";

	return $DisturbanceOut;
}

# DISTn_YEAR
sub DistYear 
{
	my $DistYear = shift(@_);

	my $CASDistYear;

	if ( isempty($DistYear) ) {
		$CASDistYear = MISSCODE;
	}
	elsif ( $DistYear ge 1880 && $DistYear le 2020 ) 
	{
		$DistYear =~ s/^\s//g;
		$DistYear =~ m/^([0-9]{4}).*$/;
		$CASDistYear = $1;
		if(!defined $CASDistYear)
		{
			$CASDistYear = ERRCODE;
		}
		#print "-----------<<$DistYear>>-----------$CASDistYear \n ";
	}
	elsif ( $DistYear eq "0" || $DistYear eq "0.0" || $DistYear !~ /[^0\.]/ ) {
		$CASDistYear = MISSCODE;
	}
	else {
		$CASDistYear = ERRCODE;
	}
	return $CASDistYear;
}

sub DisturbanceExtentUpper
{
	my $Extent;
	my $CASExtent;
	my %ExtDomain;

	($Extent) = shift(@_); 
	given ($IV) {
			when (1) {    # 1 : Phase 3
				%ExtDomain = (
					""  => MISSCODE,
					0	=> MISSCODE,
					1 => 25,
					2 => 50,
					3 => 75,
					4 => 100
				);
			}
			when ( [ 2, 3, 4 ] ) {   # 2 : AVI 2.1, 3 : AVI 2.1 +, 4 : AVI 2.1 other
				%ExtDomain = (
					""  => MISSCODE,
					0	=> MISSCODE,
					1 => 25,
					2 => 50,
					3 => 75,
					4 => 95,
					5 => 100
				);
			}
		}

	if (is_missing($Extent))
	{
		return UNDEF;
	}	
	if ( isempty($Extent)) { 
		$CASExtent = MISSCODE; 
	}
	elsif ( ! $ExtDomain{$Extent} ) { 
		$CASExtent = ERRCODE; 
	}
	else { 
		$CASExtent = $ExtDomain{$Extent}; 
	}

	return $CASExtent;
};

sub DisturbanceExtentLower
{
	my $Extent;
	my $CASExtent;
	my %ExtDomain;

	($Extent) = shift(@_);
	given ($IV) {
			when (1) {    # 1 : Phase 3
				%ExtDomain = (
					""  => MISSCODE,
					0	=> MISSCODE,
					1 => 1,
					2 => 26,
					3 => 51,
					4 => 76
				);
			}
			when ( [ 2, 3, 4 ] ) {   # 2 : AVI 2.1, 3 : AVI 2.1 +, 4 : AVI 2.1 other
				%ExtDomain = (
					""  => MISSCODE,
					0	=> MISSCODE,
					1 => 1,
					2 => 26,
					3 => 51,
					4 => 76,
					5 => 96
				);
			}
		}
	if (is_missing($Extent))
	{
		return UNDEF;
	}	
	if ( isempty($Extent) ) { $CASExtent = MISSCODE; }
	elsif ( ! $ExtDomain{$Extent} ) { $CASExtent = ERRCODE; }
	else { $CASExtent = $ExtDomain{$Extent}; }

	return $CASExtent;
};

# Determine wetland codes
# todo field name : ???
sub WetlandCodes 
{
	my $Moisture   = shift(@_);
	my $CrownCode  = shift(@_);
	my $NonForLand = shift(@_);
	my $NatNonVeg  = shift(@_);
	my $Spec1      = shift(@_);
	my $Spec2      = shift(@_);
	my $Spec1Per   = shift(@_);   #todo check how is passed Spec1Per for Phase 3

	my %NonForArray;
	my $WetlandCode = MISSCODE;

	# set everything upper case
	$Moisture   = (defined($Moisture)? uc($Moisture) : "");
	$NonForLand = (defined($NonForLand)? uc($NonForLand) : "");
	$CrownCode  = (defined($CrownCode)? uc($CrownCode) : "");
	$NonForLand = (defined($NonForLand)? uc($NonForLand) : "");
	$NatNonVeg  = (defined($NatNonVeg)? uc($NatNonVeg) : "");
	$Spec1      = (defined($Spec1)? uc($Spec1) : "");
	$Spec2      = (defined($Spec2)? uc($Spec2) : "");

	if(isempty($Spec1Per)) {$Spec1Per=0;}

	if ( $IV == 1 ) 
	{    # Phase 3
		%NonForArray = (
			"OM" => "S,O,N,S,",
			"TM" => "S,O,N,S,",
			"DS" => "M,O,N,G,",
			"FL" => "M,O,N,G,",
		);
		#BK modif
		if ( isempty($NonForLand)) {
			$WetlandCode = MISSCODE;
		}
		elsif ( $NonForArray{$NonForLand} ) {
			$WetlandCode = $NonForArray{$NonForLand};
		}
		elsif ( $Spec1 eq "SB" || $Spec1 eq "LT" || $Spec1 eq "BW" ) {
			if ( $Spec1Per == 100 ) {
				#todo add commericalism = U constraint
				$WetlandCode = "S,T,N,N,";
			}
			elsif ( $Spec2 eq "SB" || $Spec2 eq "LT" || $Spec2 eq "BW" ) {
				#todo add commericalism = U constraint
				$WetlandCode = "S,T,N,N,";
			}
		}
	}

	# else : AVI

	if ( isempty($Spec1Per)) {
		$Spec1Per = 0;
	}

	if ( $Moisture eq "W" ) 
	{
		# non forested land code
		%NonForArray = (
			"SO" => "S,O,N,S,",
			"SC" => "S,O,N,S,",
			"HG" => "M,O,N,G,",
			"HF" => "M,O,N,G,",
			"BR" => "F,O,N,G,",
		);

		if ( isempty($NonForLand) ) {
			$WetlandCode = MISSCODE;
		}
		elsif ( $NonForArray{$NonForLand} ) {
			$WetlandCode = $NonForArray{$NonForLand};
		}
		elsif ( $NatNonVeg eq "NMB" ) {
			$WetlandCode = "S,O,N,S,";
		}
	}
	else {

		# todo check with Steve if appropriate use of elsif (pending)
		# forest land code
		if ( $Spec1 eq "LT" || $Spec2 eq "LT" ) {
			given ($CrownCode) {
				when ( [ "A", "B" ] ) {
					$WetlandCode = "F,T,N,N,";
				}
				when ("C") {
					$WetlandCode = "S,T,N,N,";
				}
				when ("D") {
					$WetlandCode = "S,F,N,N,";
				}
			}
		}
		elsif ( $Spec1 eq "SB" && $Spec1Per eq 100 ) {
			given ($CrownCode) {
				when ( [ "A", "B" ] ) {
					$WetlandCode = "B,T,N,N,";
				}
				when ("C") {
					$WetlandCode = "S,T,N,N,";
				}
				when ("D") {
					$WetlandCode = "S,F,N,N,";
				}
			}
		}
		elsif ( ( $Spec1 eq "SB" || $Spec1 eq "FB" ) && $Spec2 ne "LT" ) {
			given ($CrownCode) {
				when ( [ "A", "B", "C" ] ) {
					$WetlandCode = "S,T,N,N,";
				}
				when ("D") {
					$WetlandCode = "S,F,N,N,";
				}
			}
		}
		elsif ( $Spec1 eq "SW" ) {
			given ($CrownCode) {
				when ( [ "A", "B", "C" ] ) {
					$WetlandCode = "S,T,N,N,";
				}
				when ("D") {
					$WetlandCode = "S,F,N,N,";
				}
			}
		}
		elsif ( $Spec1 eq "BW" || $Spec1 eq "PB" ) {
			given ($CrownCode) {
				when ( [ "A", "B", "C" ] ) {
					$WetlandCode = "S,T,N,N,";
				}
				when ("D") {
					$WetlandCode = "S,F,N,N,";
				}
			}
		}
	}
	return $WetlandCode;
}

sub SetInventoryVersion 
{

	# this is to set the version of the inventory using the $IV variable
	my $major = shift(@_); 
	my $minor = shift(@_); 

	# IV is a global variable inside this module
	# it indicates de Inventory Version

	given ($major) {
		when ('AVI') {
			given ($minor) {
				when ('2.1+') {    # 3 : AVI 2.1 +
					$IV = 3;
				}
				when ('2.1OTHER') {    # 4 : AVI 2.1 other
					$IV = 4;
				}
				default {               # 2 : AVI 2.1
					$IV = 2;
				}
			}
		}
		when ('PHASE') {                # 1 : Phase 3
			$IV = 1;
		}
		default {
			die(
					"Cannot match an inventory version. Major : $major, Minor : $minor"
			);
		  }
	}

}

# pad with a given expression
sub pad 
{
	my $exp   = $_[0];
	my $times = $_[1];

	if ( $times le 1 ) {
		return $exp;
	}
	else {
		return pad( $exp, $times - 1 ) . "," . $exp;
	}
}

sub Photo
{
	my $photo = shift(@_); #$_[0];
	
	if(isempty($photo) || $photo eq "0" ||  $photo =~ m/^0(.0)*$/ || uc($photo) eq uc("not known")){
		$photo = -1;
	}
	elsif($photo ne ERRCODE && $photo ne MISSCODE) 
	{

		if (!($photo =~ m/^[0-9]{4}$/) ){
			$photo = -1;
		}
	}
	return $photo;
}


sub productive_code
{
	my ($Sp1, $CCHigh, $CCLow, $HeightHigh, $HeightLow, $CrownCl) = @_;
	my $SpeciesComp;
	my $prod_for="PF";
	my $lyr_poly=0;

	if(isempty($CrownCl) )
	{
		$CrownCl = 0;
	}
	if($CrownCl =~ /[A-D]/)
	{
		$CrownCl = 1;
	}
		
	if(isempty($Sp1))
	{
		#$SpeciesComp ="XXXX MISS,0,XXXX MISS,0,XXXX MISS,0,XXXX MISS,0,XXXX MISS,0,XXXX MISS,0,XXXX MISS,0,XXXX MISS,0,XXXX MISS,0,XXXX MISS,0";

		if(( ((!is_missing($CCHigh) ||  !is_missing($CCLow)) && $CrownCl != 0) || !is_missing($HeightHigh) || !is_missing($HeightLow)) )
		#if( ( !is_missing($CCHigh) ||  !is_missing($CCLow) || !is_missing($HeightHigh) || !is_missing($HeightLow)))
		{
			$prod_for="PP";	
			$lyr_poly=1;
		}
	}
	return ($prod_for, $lyr_poly );
}

sub ABinv_to_CAS 
{

	# Called via INVENTORIES_conv_fmus.pl
	#ABinv_to_CAS($In_inventory, \%ProvSP_table, $Out_CAS, $errfile, $hPROVit{$province},$optiongroups, $pathNgrp, $TotalPROVit, $numfmu, $iters_k, $hdrinfos, $std_version, $spfers, \%spfreqprev, \$ncas, \$nlyr,\$nnfl,\$ndst, \$neco, \$ndstonly, \$necoonly, $specslogfile);
          		
	my $AB_File      = shift(@_);
	$Species_table = shift(@_);
	my $CAS_File     = shift(@_);
	my $ERRFILE      = shift(@_);
	my $nbiters      = shift(@_);
	my $optgroups    = shift(@_);
	my $pathname     = shift(@_);
	my $TotalIT      = shift(@_);
	my $numfmu       = shift(@_);
	my $iters_fmu    = shift(@_);
	my $INFOHDR_File = shift(@_);
	my $std_version  = shift(@_); 

	my $SPERRS = shift(@_); 

	my $spfreq=shift(@_);

	my $ncas=shift(@_);
	my $nlyr=shift(@_);
	my $nnfl=shift(@_);
	my $ndst=shift(@_);
	my $neco=shift(@_);
	my $ndstonly=shift(@_);
	my $necoonly=shift(@_);
	my $SPECSLOG=shift(@_);

	my $ncasprev=0;
	my $nlyrprev=0;
	my $nnflprev=0;
	my $ndstprev=0;
	my $necoprev=0;
	my $ndstonlyprev=0;
	my $necoonlyprev=0;
	my $nbpr=0;
	my $total=0;
	my $total2=0;
	my $ndrops=0;
	my $no_dst3;
	
	my $major;
	my $minor;

	my $photofile = $AB_File;

	if($photofile =~ /AB_0020/ && $photofile =~ /_1\.csv$/)
	{
		$photofile =~ s/_1\.csv$/_photo\.csv/g;
	}
	elsif($photofile =~ /AB_0026/ || $photofile =~ /AB_0027/ || $photofile =~ /AB_0028/)
	{
		$photofile = "";
	}
	else 
	{
		$photofile =~ s/\.csv$/_photo\.csv/g;
	}


	#print "file is  $AB_File \n";
	
		#my $Distpp="C0KL";
	#my $Distp=Disturbance($Distpp,1982);
	#print "disturbance is  $Distp \n";
	#if ( ($Distpp !~ /\d/ )) {
				#print "\n GOOD \n"; 		
			#}
	#exit;
	#####
	# Declare hashtable for a photoyear
	my %ABtable = ();

	# Here is the loop to interprete photoyear files when photoyear come from an other source
	if($photofile ne "")
	{
		open( ABsheets, "$photofile" )
		  || die "\n Error: Could not open file of AB sheets $photofile !\n";
		my $csv1    = Text::CSV_XS->new();
		my $nothing = <ABsheets>;            #drop header line
		if($nothing =~ /;/)
		{
			#set the separator to ; instead of default ;
			$csv1->sep_char (";");
		}
		my $nbr     = 0;
		while (<ABsheets>) {
			if ( $csv1->parse($_) ) {
				my @ABS_Record = ();
				@ABS_Record = $csv1->fields();
				my $ABkeys = $ABS_Record[0];
				$ABtable{$ABkeys} = $ABS_Record[1];
				$nbr++;

				#print("fFILE no = $ABkeys , age = $ABS_Record[1]\n"); #exit;
			}
			else {
				my $err = $csv1->error_input;
				print "Failed to parse line: $err";
				exit(1);
			}
		}
		close(ABsheets);
	}
	#print " $nbr lines in $photofile\n";

	#####

	# todo we should define well that the argument AB_File passed to <juridiction>_to_CAS
	# are always with the right extension.
	#if ( $AB_File !~ m/\.csv/ ) { $AB_File = $AB_File . ".csv"; }

	my $CAS_File_HDR =  $CAS_File . ".hdr";
	my $CAS_File_CAS =  $CAS_File . ".cas";
	my $CAS_File_LYR =  $CAS_File . ".lyr";
	my $CAS_File_NFL =  $CAS_File . ".nfl";
	my $CAS_File_DST =  $CAS_File . ".dst";
	my $CAS_File_ECO =  $CAS_File . ".eco";

	open( ABinv, "<$AB_File" )
	  || die "\n Error: Could not open Alberta 0001 input file!\n";
	open( ERRS, ">>$ERRFILE" )
	  || die "\n Error: Could not open $ERRFILE file!\n";
	open (SPERRSFILE, ">>$SPERRS") || die "\n Error: Could not open $SPERRS file!\n";

	open (SPECSLOGFILE, ">>$SPECSLOG") || die "\n Error: Could not open $SPECSLOG file!\n";

	if ( $optgroups == 1 ) 
	{

		$CAS_File_HDR = $pathname . "/ABtable.hdr";
		$CAS_File_CAS = $pathname . "/ABtable.cas";
		$CAS_File_LYR = $pathname . "/ABtable.lyr";
		$CAS_File_NFL = $pathname . "/ABtable.nfl";
		$CAS_File_DST = $pathname . "/ABtable.dst";
		$CAS_File_ECO = $pathname . "/ABtable.eco";
	}
	elsif ( $optgroups == 2 ) 
	{

		$CAS_File_HDR = $pathname . "/CanadaInventorytable.hdr";
		$CAS_File_CAS = $pathname . "/CanadaInventorytable.cas";
		$CAS_File_LYR = $pathname . "/CanadaInventorytable.lyr";
		$CAS_File_NFL = $pathname . "/CanadaInventorytable.nfl";
		$CAS_File_DST = $pathname . "/CanadaInventorytable.dst";
		$CAS_File_ECO = $pathname . "/CanadaInventorytable.eco";
	}

	if (   ( $optgroups == 0 )
		|| ( $optgroups == 1 && $nbiters == 1 )
		|| ( $optgroups == 2 && $TotalIT == 1 ) )
	{

		# open all files overwrite
		open( CASHDR, ">$CAS_File_HDR" )
		  || die "\n Error: Could not open CAS header output file!\n";
		open( CASCAS, ">$CAS_File_CAS" )
		  || die
		  "\n Error: Could not open CAS common attribute schema  file!\n";
		open( CASLYR, ">$CAS_File_LYR" )
		  || die "\n Error: Could not open CAS layer output file!\n";
		open( CASNFL, ">$CAS_File_NFL" )
		  || die
		  "\n Error: Could not open CAS non-forested land output file!\n";
		open( CASDST, ">$CAS_File_DST" )
		  || die "\n Error: Could not open CAS disturbance output file!\n";
		open( CASECO, ">$CAS_File_ECO" )
		  || die "\n Error: Could not open CAS ecological output file!\n";

		# printing table headers
		print CASCAS "CAS_ID,ORIG_STAND_ID,STAND_STRUCTURE,NUM_OF_LAYERS,IDENTIFICATION_ID,MAP_SHEET_ID,GIS_AREA,GIS_PERIMETER,INVENTORY_AREA,PHOTO_YEAR\n";
		print CASLYR "CAS_ID,SOIL_MOIST_REG,STRUCTURE_PER,LAYER,LAYER_RANK,CROWN_CLOSURE_UPPER,CROWN_CLOSURE_LOWER,HEIGHT_UPPER,HEIGHT_LOWER,PRODUCTIVE_FOR,". 		
		"SPECIES_1,SPECIES_PER_1,SPECIES_2,SPECIES_PER_2,SPECIES_3,SPECIES_PER_3,SPECIES_4,SPECIES_PER_4,SPECIES_5,SPECIES_PER_5,SPECIES_6,SPECIES_PER_6,SPECIES_7,SPECIES_PER_7,".
		"SPECIES_8,SPECIES_PER_8,SPECIES_9,SPECIES_PER_9,SPECIES_10,SPECIES_PER_10,ORIGIN_UPPER,ORIGIN_LOWER,SITE_CLASS,SITE_INDEX\n";
		print CASNFL "CAS_ID,SOIL_MOIST_REG,STRUCTURE_PER,LAYER,LAYER_RANK,CROWN_CLOSURE_UPPER,CROWN_CLOSURE_LOWER,HEIGHT_UPPER,HEIGHT_LOWER,NAT_NON_VEG,NON_FOR_ANTH,NON_FOR_VEG\n";
		print CASDST "CAS_ID,DIST_1,DIST_YR_1,DIST_EXT_UPPER_1,DIST_EXT_LOWER_1,DIST_2,DIST_YR_2,DIST_EXT_UPPER_2,DIST_EXT_LOWER_2,DIST_3,DIST_YR_3,DIST_EXT_UPPER_3,DIST_EXT_LOWER_3,LAYER\n";
		print CASECO "CAS_ID,WETLAND_TYPE,WET_VEG_COVER,WET_LANDFORM_MOD,WET_LOCAL_MOD,ECO_SITE\n";
		print CASHDR "IDENTIFICATION_ID,JURISDICTION,COORDINATE_SYS,PROJECTION,DATUM,INVENTORY_OWNER,LAND_OWNER,PERMISSION,TENURE_TYPE,INV_TYPE,INV_VERSION,INV_START_YR,INV_FINISH_YR,INV_ACQ_ID,INV_ACQ_YR,INV_UPDATE_YR\n";

		my $HDR_Record;

		my @hdr_tab=split("/",  $AB_File);
		my $sz=scalar(@hdr_tab);
		my @hdr_id=split ("-", $hdr_tab[$sz-1]);
		my ($P1, $hdr_num)=split ("_", $hdr_id[0]);

		$hdr_num =~ s/\.csv$//;
		#print "number is ". $hdr_num."\n";
		#exit;

		if($hdr_num eq "0001"){
				$HDR_Record= "1,AB,,UTM,NAD83,PROV_GOV,CROWN,,2.1,,,,,,,\n";
		}
		elsif($hdr_num eq "0002"){
				$HDR_Record= "2,AB,,,,PROV_GOV,CROWN_ALPAC,,,2.1,,,,,,,\n";
		}
		elsif($hdr_num eq "0003"){
				$HDR_Record= "3,AB,,,,PROV_GOV,CROWN_BLUERIDGE,,,2.1,,,,,,, \n";
		}
		elsif($hdr_num eq "0004"){
				$HDR_Record= "4,AB,,,,PROV_GOV,CROWN_CANFOR,,,2.1,,,,,,,\n";
		}
		elsif($hdr_num eq "0005"){
				$HDR_Record= "5,AB,,,,PROV_GOV,CROWN_DAISHOWA,,,2.1,,,,,,,\n";
		}
		elsif($hdr_num eq "0006"){
				$HDR_Record= "6,AB,,,,PROV_GOV,CROWN_GRODONBUCHANAN,,,2.1,,,,,,,\n";
		}
		elsif($hdr_num eq "0007"){
				$HDR_Record= "7,AB,,,,PROV_GOV,CROWN_MANNINGDIVERSIFIED,,,2.1,,,,,,,\n";
		}
		elsif($hdr_num eq "0008"){
				$HDR_Record= "8,AB,,,,PROV_GOV,CROWN_MILLARWESTIN,,,2.1,,,,,,,\n";
		}
		elsif($hdr_num eq "0009"){
				$HDR_Record= "9,AB,,,,PROV_GOV,CROWN_SLAVELAKEPULP,,,2.1,,,,,,,\n";
		}
		elsif($hdr_num eq "0010"){
				$HDR_Record= "10,AB,,,,PROV_GOV,CROWN_TOLKO,,,2.1,,,,,,,\n";
		}
		elsif($hdr_num eq "0011"){
				$HDR_Record= "11,AB,,,,PROV_GOV,CROWN_WELWOOD,,,2.1,,,,,,,\n";
		}
		elsif($hdr_num eq "0012"){
				$HDR_Record= "12,AB,,,,PROV_GOV,CROWN_WEYERHAUSER,,,2.1,,,,,,,\n";
		}
		elsif($hdr_num eq "0013"){
				$HDR_Record= "13,AB,,,,PROV_GOV,CROWN_FIRSTNATION,,,2.1,,,,,,,\n";
		}
		elsif($hdr_num eq "0014"){
				$HDR_Record= "14,AB,,,,INDUSTRY,ALPAC,,,2.1,,,,,,,\n";
		}
		elsif($hdr_num eq "0015"){
				$HDR_Record= "15,AB,,,,INDUSTRY,CALLING_LAKE,,,2.1,,,,,,,\n";
		}
		elsif($hdr_num eq "0016"){
				$HDR_Record= "16,AB,,,,INDUSTRY,CANFOR,,,2.1,,,,,,,\n";
		}
		elsif($hdr_num eq "0017"){
				$HDR_Record= "17,AB,,,,INDUSTRY,DAISHOWA,,,2.1,,,,,,,\n";
		}
		elsif($hdr_num eq "0018"){
				$HDR_Record= "18,AB,,,,INDUSTRY,DMI,,,2.1,,,,,,,\n";
		}
		elsif($hdr_num eq "0019"){
				$HDR_Record= "19,AB,,,,INDUSTRY,HR_FIRE,,,2.1,,,,,,,\n";
		}
		elsif($hdr_num eq "0020"){
				$HDR_Record= "20,AB,,,,INDUSTRY,SLAVELAKEPULUP,,,2.1 other,,,,,,,\n";
		}
		elsif($hdr_num eq "0021"){
				$HDR_Record= "21,AB,,,,INDUSTRY,TOLKO,,,2.1,,,,,,,\n";
		}
		elsif($hdr_num eq "0022"){
				$HDR_Record= "22,AB,,,,INDUSTRY,WEYCO,,,2.1,,,,,,,\n";
		}
		elsif($hdr_num eq "0023"){
				$HDR_Record= "23,AB,,,,INDUSTRY,WEYCO_P3,,,2.1,,,,,,,\n";
		}
		elsif($hdr_num eq "0024"){
				$HDR_Record= "24,AB,,,,INDUSTRY,WEYERHAUSER,,,2.1,,,,,,,\n";
		}
		elsif($hdr_num eq "0025"){
				$HDR_Record= "25,AB,,NAD_1983_CSRS_10TM_AEP_Forest,NAD83,PROV_GOV,CROWN,RESTRICTED,,2.1,With Revisions,1987,2008,,2012,,\n";
		}
		elsif($hdr_num eq "0026"){
				$HDR_Record= "26,AB,,,,INDUSTRY,CENEVUS,RESTRICTED,,2.1,,,,,,,\n";
		}
		elsif($hdr_num eq "0027"){
				$HDR_Record= "27,AB,,,,INDUSTRY,ALPCA,RESTRICTED,,2.1,,,,,,,\n";
		}
		elsif($hdr_num eq "0028"){
				$HDR_Record= "28,AB,,,,INDUSTRY,ALPAC,RESTRICTED,,2.1,,,,,,,\n";
		}

		else {print "no header for this file , hdr_num=$hdr_num \n";exit;}

		print CASHDR $HDR_Record . "\n";
	}
	else 
	{
		# 	open all files in append mode, so no header.
		open( CASCAS, ">>$CAS_File_CAS" )
		  || die "\n Error: Could not open GROUPCAS  output file!\n";
		open( CASLYR, ">>$CAS_File_LYR" )
		  || die "\n Error: Could not open GROUPCAS layer output file!\n";
		open( CASNFL, ">>$CAS_File_NFL" )
		  || die "\n Error: Could not open GROUPCAS non-forested file!\n";
		open( CASDST, ">>$CAS_File_DST" )
		  || die "\n Error: Could not open GROUPCAS disturbance  file!\n";
		open( CASECO, ">>$CAS_File_ECO" )
		  || die "\n Error: Could not open GROUPCAS ecological  file!\n";
		open( CASHDR, ">>$CAS_File_HDR" )
		  || die "\n Error: Could not open CAS header output file!\n";

		#open( INFOHDR, "<$INFOHDR_File" )
		#  || die "\n Error: Could not open file $INFOHDR_File !\n";
	}

	my $endstep = 0;
	
	#SetInventoryVersion( 'AVI', '2.1' );)
	#print "version $std_version\n";
	#exit;
	($major, $minor) = split(/[ ]/, $std_version, 2);
	SetInventoryVersion( $major, $minor);
	$optgroups = 0;

	print "\n iventory version set to $IV\n";
	 
	# ! I think that if we refactor the code, it would be best practice to
	# use an hash than multiple variables - EBR
	my $Record;my @Fields;my $PolyNum;
	my $CASID;
	my $MapSheetID;
	my $IdentifyID;
	my $Area;
	my $Perimeter;
	my $pr1;
	my $pr2;
	my $pr3;
	my $pr4;
	my $pr5;
	my $Mer;
	my $Rng;
	my $Twp;
	my $Gid;
	my $MoistReg;
	my $Density;
	my $Height;
	my $Sp1;
	my $Sp1Per;
	my $Sp2;
	my $Sp2Per;
	my $Sp3;
	my $Sp3Per;
	my $Sp4;
	my $Sp4Per;
	my $Sp5;
	my $Sp5Per;
	my $Struc;
	my $StrucVal;
	my $Origin;
	my $TPR;
	my $Initials;

	my $NFL;
	my $NFLPer;
	my $NatNon;
	my $AnthVeg;
	my $AnthNon;
	my $Mod1;
	my $Mod1Ext;
	my $Mod1Yr;
	my $Mod2;
	my $Mod2Ext;
	my $Mod2Yr;
	my $Data;
	my $DataYr;
	my $UMoistReg;
	my $UDensity;
	my $UHeight;
	my $USp1;
	my $USp1Per;
	my $USp2;
	my $USp2Per;
	my $USp3;
	my $USp3Per;
	my $USp4;
	my $USp4Per;
	my $USp5;
	my $USp5Per;
	my $UStruc;
	my $UStrucVal;
	my $UOrigin;
	my $UTPR;
	my $UInitials;
	my $UNFL;
	my $UNFLPer;
	my $UNatNon;
	my $UAnthVeg;
	my $UAnthNon;
	my $UMod1;
	my $UMod1Ext;
	my $UMod1Yr;
	my $UMod2;
	my $UMod2Ext;
	my $UMod2Yr;
	my $UData;
	my $UDataYr;
	my $DensityPer;
	my $DecimalHgt;
	my $StemsHA;
	my $MoistCode;

	my $IntTpr;
	my $UDensityPer;
	my $UDecimalHgt;
	my $UStemsHA;
	my $UMoistCode;

	my $UIntTpr;
	my $TlgID;
	my $SMR;
	my $USMR;
	my $StandStructureCode;
	my $StandStructureVal;
	my $UStandStructureCode;
	my $UStandStructureVal;
	my $CCHigh;
	my $CCLow;
	my $UCCHigh;
	my $UCCLow;
	my $HeightHigh;
	my $HeightLow;
	my $UHeightHigh;
	my $UHeightLow;
	my $SpeciesComp;
	my $USpeciesComp;
	my $OriginHigh;
	my $OriginLow;
	my $UOriginHigh;
	my $UOriginLow;
	my $SiteClass;
	my $SiteIndex;
	my $UnprodFor;
	my $USiteClass;
	my $USiteIndex;
	my $UUnprodFor;
	my $Wetland;

	my $NonForVeg;
	my $NonForAnth;
	my $UNatNonVeg;
	my $UNonForAnth;
	my $UNonForVeg;
	my $Dist1;	my $Dist2; my $Dist3;
	my $UDist1;	my $UDist2; my $UDist3;
	my $Dist1ExtHigh;	my $Dist2ExtHigh; my $Dist3ExtHigh;
	my $UDist1ExtHigh; 	my $UDist2ExtHigh; my $UDist3ExtHigh;
	my $Dist1ExtLow; 	my $Dist2ExtLow; my $Dist3ExtLow;
	my $UDist1ExtLow; 	my $UDist2ExtLow; my $UDist3ExtLow;

	my $NatNonVeg;
	my $Dist;
	my $UDist;

	my %herror = ();
	my $keys;

	my $CAS_Record;
	my $Lyr_Record;
	my $LYR_Record1;
	my $LYR_Record2;
	my $LYR_Record3;
	my $NFL_Record;
	my $NFL_Record1;
	my $NFL_Record2;
	my $NFL_Record3;
	my $DST_Record;
	my $PHOTOYEAR;

	my $NULL = <ABinv>;

	# new vars
	my $Source;
	my $NO;
	my $ForestKey;
	my $Ustruc;
	my $CASphotoYear;
	my $IsNFL; my $IsUNFL;
	my @SpecsPerList=();my @USpecsPerList=(); my $cpt_ind; my $justify; my $ujustify;
	my $UDist1P1; my $UDist2P1; my $UDist3P1; my $Dist1P1; my $Dist2P1; my $OR1; my $OR2; my $UR1; my $UR2; my $UR3;my $Dist3P1; my $OR3; 

	my $C_MOIST_REG;
	my $C_DENSITY;
	my $C_HEIGHT;
	my $C_SP1;
	my $C_SP1_PER;
	my $C_SP2;
	my $C_SP2_PER;
	my $C_SP3;
	my $C_SP3_PER;
	my $C_SP4;
	my $C_SP4_PER;
	my $C_SP5;
	my $C_SP5_PER;

	my $C_STRUC;
	my $C_STRUC_VAL;
	my $C_ORIGIN;
	my $C_TPR;
	my $C_INITIALS;
	my $C_NFL;
	my $C_NFL_PER;
	my $C_NAT_NON;
	my $C_ANTH_VEG;
	my $C_ANTH_NON;
				
	my $C_MOD1;
	my $C_UMOD1;
	my $C_MOD1_EXT;
	my $C_MOD1_YR;

	my $C_MOD2;
	my $C_MOD2_EXT;
	my $C_MOD2_YR;
			
	my $C_MOD3;
	my $C_MOD3_EXT;
	my $C_MOD3_YR;
			
			
	my $C_DATA;
	my $C_DATA_YR;
	my $C_UMOIST_REG;
	my $C_UDENSITY;
	my $C_UHEIGHT;
	my $C_USP1;
	my $C_USP1_PER;
	my $C_USP2;
	my $C_USP2_PER;
	my $C_USP3;
	my $C_USP3_PER;
	my $C_USP4;
	my $C_USP4_PER;
	my $C_USP5;
	my $C_USP5_PER;
	my $C_USTRUC;
	my $C_USTRUC_VAL;
	my $C_UORIGIN;
	my $C_UTPR;
	my $C_UNITIALS;
	my $C_UNFL;
	my $C_UNFL_PER;
	my $C_UNAT_NON;
	my $C_UANTH_VEG;
	my $C_UANTH_NON;
				
	my $C_UMOD1_EXT;
	my $C_UMOD1_YR;

	my $C_UMOD2;
	my $C_UMOD2_EXT;
	my $C_UMOD2_YR;
						
	my $C_UMOD3;
	my $C_UMOD3_EXT;
	my $C_UMOD3_YR;
			
	my $C_UDATA;
	my $C_UDATA_YR;
	my %Illegal_Dist_list=();

	%Illegal_Dist_list = (		 
				"WA" => "OT",
				"CS" => "OT",
				"SA" => "OT",
				"TM" => "OT",
				"OM" => "OT",
				"DS" => "OT",
				"AD" => "OT",
				"UP" => "OT",
				"TL" => "OT",
				"PI" => "OT",
				"OR" => "OT",
				"NC" => "OT",
				"ID" => "OT",				
				"DE" => "OT",
				"CY" => "OT",
				"CW" => "OT",
				"CO" => "OT",
				"BD" => "OT",
				"AS" => "OT",
				"BR" => "OT",
				"SU" => "OT",
				"SL" => "OT",
				"PR" => "OT",
				"OC" => "OT",
				"MT" => "OT",
				"FT" => "OT",
				"CL" => "OT"
	);
	##############################################
	#my $test="1940.0";
	#OriginUpper($test);

	my $csv = Text::CSV_XS->new({binary          => 1,
			     sep_char    => ";" });
	open my $ABinv, "<", $AB_File
	or die " \n Error: Could not open AB input file $AB_File: $!";

	my @tfilename= split ("/", $AB_File);
	my $nps=scalar(@tfilename);
	my $CREATE_NFL_LYR	 = 0; my $CREATE_UNFL_LYR	 = 0; 
	my ($UMod3,$UMod3Ext,$UMod3Yr);
	my ($Mod3,$Mod3Ext,$Mod3Yr);
	$Glob_filename= $tfilename[$nps-1];

	$csv->column_names( $csv->getline($ABinv) );

	while ( my $row = $csv->getline_hr($ABinv) )
	{  
		#print "CAS_ID is $row->{CAS_ID}  and AREA is $row->{AREA} \n"; #exit(0);

		#################################################################

		# map fields
		# todo check that every field is well mapped for every inventory
		# this is for AVI  PHASE3_KEY
		my $TP3=$row->{PHASE3_KEY};
		if (defined $TP3)
		{
			$keys="standard PHASE 3\n"; 
			$IV=1;  
			$herror{$keys}++;
		}

		$CASID      = $row->{CAS_ID};
		if (!defined($CASID))
		{
			print "undefined casid at $row->{XCoord} and $row->{YCoord}\n";
			next;
		}
		next if ($CASID eq "CAS_ID");

		$Glob_CASID=$row->{CAS_ID};
	    ($pr1,$pr2,$pr3, $pr4, $pr5)     =  split("-", $row->{CAS_ID} ); 
	    $PolyNum = $pr4;   	    
        $MapSheetID   =  $pr3; 
        $MapSheetID =~ s/x+//;
        if (isempty($MapSheetID ))
        {
        	$MapSheetID = UNDEF;
        }
        $IdentifyID   =  $row->{HEADER_ID};     	
		$PHOTOYEAR  = $ABtable{$CASID};
		$Area       = $row->{GIS_AREA};
		$Perimeter  = $row->{GIS_PERI};
		
		if(!defined $Perimeter )
		{
			print "Perimeter undef for casid $CASID\n";
			$Perimeter = UNDEF;
		}

			# $Mer        = $row->{MER};
			# $Rng        = $row->{RNG};
			# $Twp        = $row->{TWP};
			# $Gid        = $row->{GID};
			# $Source     = $row->{SOURCE};
			# $NO         = $row->{POLY_NUM};
			# $ForestKey  = $row->{POLY_NUM};
		#ATT_MOIST_;ATT_DENSIT;ATT_HEIGHT;ATT_SP1;ATT_SP1_PE;ATT_SP2;ATT_SP2_PE;ATT_SP3;ATT_SP3_PE;ATT_SP4;ATT_SP4_PE;ATT_SP5;ATT_SP5_PE;ATT_STRUC;ATT_STRUC_;ATT_ORIGIN;ATT_TPR;ATT_INITIA;ATT_NFL;
		#ATT_NFL_PE;ATT_NAT_NO;ATT_ANTH_V;ATT_ANTH_N;ATT_MOD1;ATT_MOD1_E;ATT_MOD1_Y;ATT_MOD2;ATT_MOD2_E;ATT_MOD2_Y;ATT_DATA;ATT_DATA_Y;ATT_UMOIST;ATT_UDENSI;ATT_UHEIGH;ATT_USP1;ATT_USP1_P;
		#ATT_USP2;ATT_USP2_P;ATT_USP3;ATT_USP3_P;ATT_USP4;ATT_USP4_P;ATT_USP5;ATT_USP5_P;ATT_USTRUC;ATT_USTR_1;ATT_UORIGI;ATT_UTPR;ATT_UINITI;ATT_UNFL;ATT_UNFL_P;ATT_UNAT_N;ATT_UANTH_;ATT_UANTH1;
		#ATT_UMOD1;ATT_UMOD1_;ATT_UMOD11;ATT_UMOD2;ATT_UMOD2_;ATT_UMOD21;ATT_UDATA;ATT_UDATA_;ATT_TRM
			

		if($pr1 eq "AB_0001")
		{
			#print "choosing header parameters for AB_0001\n";

			$C_MOIST_REG = "ATT_MOIST";
			$C_DENSITY = "ATT_DENSIT";
			$C_HEIGHT = "ATT_HEIGHT";
			$C_SP1 = "ATT_SP1";
			$C_SP1_PER = "ATT_SP1_PE";
			$C_SP2 = "ATT_SP2";
			$C_SP2_PER = "ATT_SP2_PE";
			$C_SP3 = "ATT_SP3";
			$C_SP3_PER = "ATT_SP3_PE";
			$C_SP4 = "ATT_SP4";
			$C_SP4_PER = "ATT_SP4_PE";
			$C_SP5 = "ATT_SP5";
			$C_SP5_PER = "ATT_SP5_PE";

			$C_STRUC = "ATT_STRUC";
			$C_STRUC_VAL = "ATT_STRUC_";
			$C_ORIGIN = "ATT_ORIGIN";
			$C_TPR = "ATT_TPR";
			$C_INITIALS = "ATT_INITIA";
			$C_NFL = "ATT_NFL";
			$C_NFL_PER = "ATT_NFL_PE";
			$C_NAT_NON = "ATT_NAT_NO";
			$C_ANTH_VEG = "ATT_ANTH_V";
			$C_ANTH_NON = "ATT_ANTH_N";
						
			$C_MOD1 = "ATT_MOD1";
			$C_MOD1_YR = "ATT_MOD1_Y";
			$C_MOD1_EXT = "ATT_MOD1_E";

			$C_MOD2 = "ATT_MOD2";
			$C_MOD2_EXT = "ATT_MOD2_E";
			$C_MOD2_YR = "ATT_MOD2_Y";
					
			$C_MOD3 = "ATT_MOD3";
			$C_MOD3_EXT = "ATT_MOD3_E";
			$C_MOD3_YR = "ATT_MOD3_Y";
		
			$C_DATA = "ATT_DATA";
			$C_DATA_YR = "ATT_DATA_Y";
			$C_UMOIST_REG = "ATT_UMOIST";
			$C_UDENSITY = "ATT_UDENSI";
			$C_UHEIGHT = "ATT_UHEIGH";
			$C_USP1 = "ATT_USP1";
			$C_USP1_PER = "ATT_USP1_P";
			$C_USP2 = "ATT_USP2";
			$C_USP2_PER = "ATT_USP2_P";
			$C_USP3 = "ATT_USP3";
			$C_USP3_PER = "ATT_USP3_P";
			$C_USP4 = "ATT_USP4";
			$C_USP4_PER = "ATT_USP4_P";
			$C_USP5 = "ATT_USP5";
			$C_USP5_PER = "ATT_USP5_P";
			$C_USTRUC = "ATT_USTRUC";
			$C_USTRUC_VAL = "ATT_USTR_1";
			$C_UORIGIN = "ATT_UORIGI";
			$C_UTPR = "ATT_UTPR";
			$C_UNITIALS = "ATT_UNITI";
			$C_UNFL = "ATT_UNFL";
			$C_UNFL_PER = "ATT_UNFL_P";
			$C_UNAT_NON = "ATT_UNAT_N";
			$C_UANTH_VEG = "ATT_UANTH_";
			$C_UANTH_NON = "ATT_UANTH_1";
						
			$C_UMOD1_EXT = "ATT_UMOD11";
			$C_UMOD1_YR = "ATT_UMOD1_";
			$C_UMOD1 = "ATT_UMOD1";

			$C_UMOD2 = "ATT_UMOD2";
			$C_UMOD2_EXT = "ATT_UMOD21";
			$C_UMOD2_YR = "ATT_UMOD2_";
					
			$C_UMOD3 = "ATT_UMOD3";
			$C_UMOD3_EXT = "ATT_UMOD31";
			$C_UMOD3_YR = "ATT_UMOD3_";
					
			$C_UDATA = "ATT_UDATA";
			$C_UDATA_YR = "ATT_UDATA_";
		}
		else 
		{

			$C_MOIST_REG = "MOIST_REG";
			$C_DENSITY = "DENSITY";
			$C_HEIGHT = "HEIGHT";
			$C_SP1 = "SP1";
			$C_SP1_PER = "SP1_PER";
			$C_SP2 = "SP2";
			$C_SP2_PER = "SP2_PER";
			$C_SP3 = "SP3";
			$C_SP3_PER = "SP3_PER";
			$C_SP4 = "SP4";
			$C_SP4_PER = "SP4_PER";
			$C_SP5 = "SP5";
			$C_SP5_PER = "SP5_PER";

			$C_STRUC = "STRUC";
			$C_STRUC_VAL = "STRUC_VAL";
			$C_ORIGIN = "ORIGIN";
			$C_TPR = "TPR";
			$C_INITIALS = "INITIALS";
			$C_NFL = "NFL";
			$C_NFL_PER = "NFL_PER";
			$C_NAT_NON = "NAT_NON";
			$C_ANTH_VEG = "ANTH_VEG";
			$C_ANTH_NON = "ANTH_NON";
						
			$C_MOD1 = "MOD1";
			$C_MOD1_EXT = "MOD1_EXT";
			$C_MOD1_YR = "MOD1_YR";

			$C_MOD2 = "MOD2";
			$C_MOD2_EXT = "MOD2_EXT";
			$C_MOD2_YR = "MOD2_YR";
					
			$C_MOD3 = "MOD3";
			$C_MOD3_EXT = "MOD3_EXT";
			$C_MOD3_YR = "MOD3_YR";
					
					
			$C_DATA = "DATA";
			$C_DATA_YR = "DATA_YR";
			$C_UMOIST_REG = "UMOIST_REG";
			$C_UDENSITY = "UDENSITY";
			$C_UHEIGHT = "UHEIGHT";
			$C_USP1 = "USP1";
			$C_USP1_PER = "USP1_PER";
			$C_USP2 = "USP2";
			$C_USP2_PER = "USP2_PER";
			$C_USP3 = "USP3";
			$C_USP3_PER = "USP3_PER";
			$C_USP4 = "USP4";
			$C_USP4_PER = "USP4_PER";
			$C_USP5 = "USP5";
			$C_USP5_PER = "USP5_PER";
			$C_USTRUC = "USTRUC";
			$C_USTRUC_VAL = "USTRUC_VAL";
			$C_UORIGIN = "UORIGIN";
			$C_UTPR = "UTPR";
			$C_UNITIALS = "UNITIALS";
			$C_UNFL = "UNFL";
			$C_UNFL_PER = "UNFL_PER";
			$C_UNAT_NON = "UNAT_NON";
			$C_UANTH_VEG = "UANTH_VEG";
			$C_UANTH_NON = "UANTH_NON";
						
			$C_UMOD1 = "UMOD1";
			$C_UMOD1_EXT = "UMOD1_EXT";
			$C_UMOD1_YR = "UMOD1_YR";

			$C_UMOD2 = "UMOD2";
			$C_UMOD2_EXT = "UMOD2_EXT";
			$C_UMOD2_YR = "UMOD2_YR";
					
			$C_UMOD3 = "UMOD3";
			$C_UMOD3_EXT = "UMOD3_EXT";
			$C_UMOD3_YR = "UMOD3_YR";
					
			$C_UDATA = "UDATA";
			$C_UDATA_YR = "UDATA_YR";	
		}

		$MoistReg   = $row->{$C_MOIST_REG};
		$Density    = $row->{$C_DENSITY};
		$Height     = $row->{$C_HEIGHT};
		$Sp1        = $row->{$C_SP1};
		$Sp1Per     = $row->{$C_SP1_PER};
		$Sp2        = $row->{$C_SP2};
		$Sp2Per     = $row->{$C_SP2_PER};
		$Sp3        = $row->{$C_SP3};
		$Sp3Per     = $row->{$C_SP3_PER};
		$Sp4        = $row->{$C_SP4};
		$Sp4Per   = $row->{$C_SP4_PER};
		$Sp5      = $row->{$C_SP5};
		$Sp5Per   = $row->{$C_SP5_PER};

		$Struc    = $row->{$C_STRUC};
		$StrucVal = $row->{$C_STRUC_VAL};
		$Origin   = $row->{$C_ORIGIN};
		$TPR      = $row->{$C_TPR};
		# $Initials = $row->{INITIALS};
		$NFL      = $row->{$C_NFL};
		$NFLPer   = $row->{$C_NFL_PER};
		$NatNon   = $row->{$C_NAT_NON};
		$AnthVeg  = $row->{$C_ANTH_VEG};
		$AnthNon  = $row->{$C_ANTH_NON};
			
		$Mod1     = $row->{$C_MOD1};
		$UMod1     = $row->{$C_UMOD1};
		$Mod1Ext  = $row->{$C_MOD1_EXT};
		$Mod1Yr   = $row->{$C_MOD1_YR};

		if ( exists $row->{$C_MOD2} ) 
		{
			$Mod2    = $row->{$C_MOD2};
			$Mod2Ext = $row->{$C_MOD2_EXT};
			$Mod2Yr  = $row->{$C_MOD2_YR};
		}
		else
		{
			$Mod2    = MISSCODE;
			$Mod2Ext = MISSCODE;
			$Mod2Yr  = MISSCODE;
		}

		if ( exists $row->{$C_MOD3} ) 
		{
			$Mod3    = $row->{$C_MOD3};
			$Mod3Ext = $row->{$C_MOD3_EXT};
			$Mod3Yr  = $row->{$C_MOD3_YR};
		}
		else
		{
			$Mod3    = MISSCODE;
			$Mod3Ext = MISSCODE;
			$Mod3Yr  = MISSCODE;
		}
		
		
		# $Data      = $row->{$C_DATA};
		# $DataYr    = $row->{DATA_YR};
		$UMoistReg = $row->{$C_UMOIST_REG};
		$UDensity  = $row->{$C_UDENSITY};
		$UHeight   = $row->{$C_UHEIGHT};
		$USp1      = $row->{$C_USP1};
		$USp1Per   = $row->{$C_USP1_PER};
		$USp2      = $row->{$C_USP2};
		$USp2Per   = $row->{$C_USP2_PER};
		$USp3      = $row->{$C_USP3};
		$USp3Per   = $row->{$C_USP3_PER};
		$USp4      = $row->{$C_USP4};
		$USp4Per   = $row->{$C_USP4_PER};
		$USp5      = $row->{$C_USP5};
		$USp5Per   = $row->{$C_USP5_PER};
		$Ustruc    = $row->{$C_USTRUC};
		$UStrucVal = $row->{$C_USTRUC_VAL};
		$UOrigin   = $row->{$C_UORIGIN};
		$UTPR      = $row->{$C_UTPR};
		# $UInitials = $row->{$C_UNITIALS};
		$UNFL      = $row->{$C_UNFL};
		$UNFLPer   = $row->{$C_UNFL_PER};
		$UNatNon   = $row->{$C_UNAT_NON};
		$UAnthVeg  = $row->{$C_UANTH_VEG};
		$UAnthNon  = $row->{$C_UANTH_NON};
			
		$UMod1Ext  = $row->{$C_UMOD1_EXT};
		$UMod1Yr   = $row->{$C_UMOD1_YR};

		if ( exists $row->{$C_UMOD2} ) 
		{
			$UMod2    = $row->{$C_UMOD2};
			$UMod2Ext = $row->{$C_UMOD2_EXT};
			$UMod2Yr  = $row->{$C_UMOD2_YR};
		}
		else 
		{
			$UMod2    = UNDEF;
			$UMod2Ext = UNDEF;
			$UMod2Yr  = UNDEF;
		}

		if ( exists $row->{$C_UMOD3} ) 
		{
			$UMod3    = $row->{$C_UMOD3};
			$UMod3Ext = $row->{$C_UMOD3_EXT};
			$UMod3Yr  = $row->{$C_UMOD3_YR};
		}
		else 
		{
			$UMod3    = UNDEF;
			$UMod3Ext = UNDEF;
			$UMod3Yr  = UNDEF;
		}
			
		# $UData   = $row->{$C_UDATA};
		# $UDataYr = $row->{$C_UDATA_YR};


		$StandStructureCode = StandStructure($Struc);
		$StandStructureVal = StandStructureValue($StrucVal);
		
		if ( $StandStructureCode eq ERRCODE || $StandStructureVal eq ERRCODE) {
			$keys = "Struc (" . $Struc . ")= " . "Struc_val-sp1-usp1----mod1-umod1****" . $StrucVal."-".$Sp1."-".$USp1."-----".$Mod1."-".$UMod1;
			$herror{$keys}++;
		}

		#BK -- checking overstory and understory standstructure percentage
		if(!isempty($Struc) &&  !isempty($UStruc) && $Struc ne $UStruc)
		{
			print "HOW CAN STRUC != USTRUC ($Struc,$UStruc)\n";
			exit;
		}

		if(!isempty($Struc) &&  !isempty($UStruc) &&  ($StrucVal + $UStrucVal !=10))
		{
			print "HOW CAN STRUCVAL+ USTRUCVAL != 10\n";
			exit;
		}

		$UStandStructureCode = $StandStructureCode;
		$UStandStructureVal = StandStructureValue($UStrucVal);
		$UStandStructureVal = UNDEF; 
		if (!isempty($UStruc) && ( $UStandStructureCode eq ERRCODE || $UStandStructureVal eq ERRCODE) )
		{
			$keys = "UStruc (" . $UStruc . ")= " . "USTAND_STRUCTURE:" . $UStandStructureCode;
			$herror{$keys}++;
		}

		$CCHigh = CCUpper($Density);
		$CCLow  = CCLower($Density);
		if($CCHigh  eq ERRCODE   || $CCLow  eq ERRCODE) 
		{ 
			$keys="Density"."#".$Density;
			$herror{$keys}++;									
		}

		$UCCHigh = CCUpper($UDensity);
		$UCCLow  = CCLower($UDensity);
		if($UCCHigh  eq ERRCODE   || $UCCLow  eq ERRCODE) 
		{ 
			$keys="Understory Density"."#".$UDensity;
			$herror{$keys}++;									
		}

		# intervals to height calls added by SGC. This is important.
		$HeightHigh = StandHeight($Height);
		$HeightLow  = StandHeight($Height);
		$justify=1;
	 	if($HeightHigh  eq ERRCODE   || $HeightLow  eq ERRCODE) 
	 	{ 
			$keys="Height"."#".$Height;
			$herror{$keys}++;									
		}
		if($HeightHigh  eq MISSCODE   || $HeightLow  eq MISSCODE) 
		{ 
			if(isempty($Sp1) || $Sp1 eq "SC" || $Sp1 eq "SO" )
			{
				$HeightHigh = UNDEF;
				$HeightLow = UNDEF;    
			}	
			elsif(($Mod1 eq "BU" ||$Mod1 eq "CC" ||$Mod1 eq "SN")  && ($Mod1Ext eq "5" || $Mod1Ext eq "4"))
			{
				$HeightHigh = 1;
				$HeightLow = 0;  
				$justify = 0;  
			}
			else 
			{
				#$keys="NULL Height"."#".$Height."#species1#".$Sp1."#Disturbance#".$Mod1."#Extent#".$Mod1Ext;
				#$herror{$keys}++;
			}								
		}

		if(defined($Sp1) &&  ($Sp1 eq "SC" || $Sp1 eq "SO" ))
		{
			$CREATE_NFL_LYR	 = 1; 
			$keys=" species SP1 = SC or SO  *** will create nfl layer";
			$herror{$keys}++;
			if(isempty ($NFL))
			{
				$UNFL = $Sp1;
			}
		}	

		if(defined($USp1) &&  ($USp1 eq "SC" || $USp1 eq "SO" ))
		{
			$CREATE_UNFL_LYR	 = 1; 
			$keys=" species USP1 = SC or SO *** will create nfl layer";
			$herror{$keys}++;
			if(isempty ($UNFL))
			{
				$UNFL = $USp1;
			}
		}	


		if($HeightHigh >0 && $justify){$HeightHigh=$HeightHigh+0.5;}
		if($HeightLow >0.5 && $justify){$HeightLow=$HeightLow-0.5;}

		$UHeightHigh = StandHeight($UHeight);
		$UHeightLow  = StandHeight($UHeight);
		$ujustify = 1; 
		if($UHeightHigh  eq MISSCODE   || $UHeightLow  eq MISSCODE)
		{ 
			if(isempty($USp1) || $USp1 eq "SC" || $USp1 eq "SO" )
			{
				$UHeightHigh = UNDEF;
				$UHeightLow = UNDEF;    
			}
			elsif( (($UMod1 eq "BU" || $UMod1 eq "CC" ||$UMod1 eq "SN") && ($UMod1Ext eq "5" || $UMod1Ext eq "4")) )
			{
				$UHeightHigh = 1;
				$UHeightLow = 0;  
				$ujustify = 0;    
			}	
			else {
					#$keys="NULL understorey Height"."#".$UHeight."#species1#".$USp1."#Disturbance#".$UMod1."#Extent#".$UMod1Ext;
					#$herror{$keys}++;
			}								
		}
		if($UHeightHigh >0 && $ujustify){$UHeightHigh=$UHeightHigh+0.5;}
		if($UHeightLow >0.5 && $ujustify){$UHeightLow=$UHeightLow-0.5;}


		$SpeciesComp = Species(	$Sp1, $Sp1Per, $Sp2, $Sp2Per, $Sp3, $Sp3Per, $Sp4, $Sp4Per, $Sp5, $Sp5Per, $spfreq);

		@SpecsPerList  = split(",", $SpeciesComp);  
		for($cpt_ind=0; $cpt_ind<=4; $cpt_ind++)
		{  
			my $posi=$cpt_ind*2;
        	if($SpecsPerList[$posi]  eq SPECIES_ERRCODE && $Sp1 ne "SC"  && $Sp1 ne "SO") 
			{ 
				$keys="Species#".$cpt_ind."#sp1=#"."$Sp1"."#sp2=#"."$Sp2"."#sp3=#"."$Sp3"."#sp4=#"."$Sp4"."#sp5=#"."$Sp5";
              	$herror{$keys}++; 
			}
   		}
		my $total=$SpecsPerList[1] + $SpecsPerList[3]+ $SpecsPerList[5] +$SpecsPerList[7] +$SpecsPerList[9];
	
		if($total != 100 && $total != 0)
		{
			$keys="total perct !=100 (log on purpose---corrected in the script)"."#$total#".$SpeciesComp."#original#".$Sp1.",".$Sp1Per.",".$Sp2.",".$Sp2Per.",".$Sp3.",".$Sp3Per.",".$Sp4.",".$Sp4Per.",".$Sp5.",".$Sp5Per;
			$herror{$keys}++; 
			#$errspec=1;
			if($total == 80 && $SpecsPerList[1] == 50 && $SpecsPerList[3] == 20 && $SpecsPerList[5] == 10)
			{
				$SpecsPerList[1]=60;
				$SpecsPerList[3]=30;
			}
			elsif($total == 730 && $SpecsPerList[1] == 700 && $SpecsPerList[3] == 30)
			{
				$SpecsPerList[1] = 70;
			}
			elsif($total == 90 && $SpecsPerList[1] == 90)
			{
				$SpecsPerList[1] = 100;
			}
			elsif($total == 90 && $SpecsPerList[1]== 80 && $SpecsPerList[3] == 10)
			{
				$SpecsPerList[1]= 90;
			}
			elsif($total == 110 && $SpecsPerList[1] == 60 && $SpecsPerList[3] == 30 && $SpecsPerList[5] == 20)
			{
				$SpecsPerList[1] = 50;
			}
			elsif($total ==40 && $SpecsPerList[1]==0 && $SpecsPerList[3]==20 && $SpecsPerList[5]==20)
			{
				$SpecsPerList[1] = 60;
			}
			$SpeciesComp=$SpecsPerList[0].",".$SpecsPerList[1].",".$SpecsPerList[2].",".$SpecsPerList[3].",". $SpecsPerList[4].",".$SpecsPerList[5].",".$SpecsPerList[6].",".$SpecsPerList[7].",".$SpecsPerList[8].",".$SpecsPerList[9];
			$total=$SpecsPerList[1]+$SpecsPerList[3]+$SpecsPerList[5]+$SpecsPerList[7]+$SpecsPerList[9];
			if($total != 100 && $total != 0 )
			{
				$keys=" bizarre total perct !=100"."#$total#".$SpeciesComp."#original#".$Sp1.",".$Sp1Per.",".$Sp2.",".$Sp2Per.",".$Sp3.",".$Sp3Per.",".$Sp4.",".$Sp4Per.",".$Sp5.",".$Sp5Per;
				$herror{$keys}++; 
			}
		}
		if(($total == 0 &&  !isempty($Sp1)))
		{
			$keys="total perct null with leading species"."#$total#".$SpeciesComp."#original#".$Sp1.",".$Sp1Per.",".$Sp2.",".$Sp2Per.",".$Sp3.",".$Sp3Per.",".$Sp4.",".$Sp4Per.",".$Sp5.",".$Sp5Per;
			$herror{$keys}++; 
		}
		$SpeciesComp = $SpeciesComp.",XXXX UNDF,0,XXXX UNDF,0,XXXX UNDF,0,XXXX UNDF,0,XXXX UNDF,0";
		
		$USpeciesComp = Species($USp1,    $USp1Per, $USp2,    $USp2Per, $USp3,$USp3Per, $USp4,    $USp4Per, $USp5,    $USp5Per,$spfreq);

		@USpecsPerList  = split(",", $USpeciesComp);  
		for($cpt_ind=0; $cpt_ind<=4; $cpt_ind++)
		{  
			my $posi=$cpt_ind*2;
        	if($USpecsPerList[$posi]  eq SPECIES_ERRCODE && $USp1 ne "SC"  && $USp1 ne "SO") 
			{ 
				$keys ="understory Species#".$cpt_ind."#usp1=#"."$USp1"."#usp2=#"."$USp2"."#usp3=#"."$USp3"."#usp4=#"."$USp4"."#usp5=#"."$USp5";
              	$herror{$keys}++; 
			}
   		}
		my $utotal=$USpecsPerList[1] + $USpecsPerList[3]+ $USpecsPerList[5] +$USpecsPerList[7] +$USpecsPerList[9];
	
		if($utotal != 100 && $utotal != 0 )
		{
			$keys=" understory total perct !=100"."#$utotal#".$USpeciesComp."#original#".$USp1.",".$USp1Per.",".$USp2.",".$USp2Per.",".$USp3.",".$USp3Per.",".$USp4.",".$USp4Per.",".$USp5.",".$USp5Per;
			$herror{$keys}++; 
			if($utotal ==80 && $USp1Per==50 && $USp2Per==20 && $USp3Per==10)
			{
				$USp1Per=60;
				$USp2Per=30;
			}
			elsif($utotal ==730 && $USp1Per==700 && $USp2Per==30 && $USp3Per==10)
			{
				$USp1Per=70;
			}
			elsif($utotal ==90 && $USp1Per==90)
			{
				$Sp1Per=100;
			}
			elsif($utotal ==110 && $USp1Per==60 && $USp2Per==30 && $USp3Per==20)
			{
				$USp1Per=50;
			}
			elsif($utotal ==40 && $USp1Per==0 && $USp2Per==20 && $USp3Per==20)
			{
				$USp1Per=60;
			}
			$USpeciesComp=$USpecsPerList[0].",".$USp1Per.",".$USpecsPerList[2].",".$USp2Per.",". $USpecsPerList[4].",".$USp3Per.",".$USpecsPerList[6].",".$USp4Per.",".$USpecsPerList[8].",".$USp5Per;
			$utotal=$USp1Per+$USp2Per+$USp3Per+$USp4Per+$USp5Per;
			if($utotal != 100 && $utotal != 0 )
			{
				$keys=" bizarre understory total perct !=100"."#$utotal#".$USpeciesComp."#original#".$USp1.",".$USp1Per.",".$USp2.",".$USp2Per.",".$USp3.",".$USp3Per.",".$USp4.",".$USp4Per.",".$USp5.",".$USp5Per;
				$herror{$keys}++; 
			}
		}
		$USpeciesComp = $USpeciesComp.",".MISSCODE.",0,".MISSCODE.",0,".MISSCODE.",0,".MISSCODE.",0,".MISSCODE.",0";
		
		if(!defined $Origin){$Origin="";}
		$OriginHigh  = OriginUpper($Origin);
		$OriginLow   = OriginLower($Origin);
		
		if ( $OriginHigh eq ERRCODE || $OriginLow eq ERRCODE)
		{
			$keys = "ORIGIN#".$Origin;
			$herror{$keys}++;
		}
		elsif ( ($OriginHigh >0 &&   $OriginHigh <1600)||  $OriginHigh >2014)
		{
			$keys = " BOUNDS Upper ORIGIN#".$Origin;
			$herror{$keys}++;
			$OriginHigh =ERRCODE;
			$OriginLow =ERRCODE;
		}

		if ( $OriginHigh eq MISSCODE && !isempty($Sp1) && $Sp1 ne "SC" && $Sp1 ne "SO") 
		{
			$keys = "null ORIGIN#".$Origin."#species1#".$Sp1;
			$herror{$keys}++;
		}

		$UOriginHigh = OriginUpper($UOrigin);
		$UOriginLow  = OriginLower($UOrigin);
			
		if ( $UOriginHigh eq ERRCODE || $UOriginLow eq ERRCODE) 
		{
			$keys = "UORIGIN (" . $UOrigin . ")= " . "UORIGIN_UPPER:" . $UOriginHigh . " UORIGIN_LOWER". $UOriginLow ;
			$herror{$keys}++;
		}
		elsif ( ($UOriginHigh >0 &&   $UOriginHigh <1600)||  $UOriginHigh >2014) 
		{
			$keys = " BOUNDS Upper ORIGIN#".$UOrigin;
			$herror{$keys}++;
			$UOriginHigh =ERRCODE;
			$UOriginLow =ERRCODE;
		}

		if ( $UOriginHigh eq MISSCODE && !isempty($USp1) && $USp1 ne "SC" && $USp1 ne "SO")
		{
			if(isempty($UOrigin))
			{
				$UOrigin="";
			}
			$keys = "null understorey ORIGIN#".$UOrigin."#species1#".$USp1;
			$herror{$keys}++;
		}
			
		$SiteClass   = Site($TPR);

		if ( $SiteClass eq ERRCODE ) 
		{
			$keys = "TPR" . "#" . $TPR;
			$herror{$keys}++;
		}

		$SiteIndex  = UNDEF;         #"";
		$UnprodFor  = UNDEF;         #"";
			
		$USiteClass = Site($UTPR);
		if ( $USiteClass eq ERRCODE )
		{
			$keys = "UTPR" . "#" . $UTPR;
			$herror{$keys}++;
		}
			
		$USiteIndex = UNDEF;         #"";
		$UUnprodFor = UNDEF;         #"";

		$SMR  = SoilMoistureRegime($MoistReg, $Sp1);
		$USMR = SoilMoistureRegime($UMoistReg, $Sp1);
		if($USMR eq -1)
		{
			# special case ($UMoistReg eq 0)
			$USMR = $SMR;
		}

		if ( $SMR eq ERRCODE ) 
		{
			$keys = "MoistReg" . "#" . $MoistReg;
			$herror{$keys}++;
		}
		if ( $USMR eq ERRCODE ) 
		{
			$keys = "UMoistReg" . "#" . $UMoistReg;
			$herror{$keys}++;
		}
			
		$Wetland    =   WetlandCodes( $SMR, $Density, $NFL, $NatNon, $Sp1, $Sp2, $Sp1Per );

		# ===== Non-forested Land =====
		my $NonForAnth2 = MISSCODE;
		my $NatNonVeg2 = MISSCODE;

		$NatNonVeg = NaturallyNonVeg($NatNon);
		if ( $NatNonVeg eq ERRCODE ) 
		{
			$NonForAnth2 = NonForestedAnth($NatNon);
			#$keys = "NatNon" . "#" . $NatNon. "### has been translated by Nonforanth $NonForAnth2 ";
			$keys = "NatNon" . "#" . $NatNon. "### has been translated by NonForAnth";
			$herror{$keys}++;
			# if ( $NonForAnth2 eq ERRCODE )
			# {
			# 	$keys = "NatNon" . "#" . $NatNon;
			# 	$herror{$keys}++;
			# }			
		}

		if (!isempty($AnthNon)) 
		{
			$NonForAnth = NonForestedAnth($AnthNon);
			if ( $NonForAnth eq ERRCODE )
			{
				$NatNonVeg2 = NaturallyNonVeg($AnthNon);
				$keys = "AnthNon" . "#" . $AnthNon. "### has been translated by NatNonVeg";
				$herror{$keys}++;
				# if ( $NatNonVeg2 eq ERRCODE )
				# {
				# 	$keys = "AnthNon" . "#" . $AnthNon;
				# 	$herror{$keys}++;
				# }	
			}
		}
		else 
		{
			$NonForAnth = NonForestedAnth($AnthVeg);
			if ( $NonForAnth eq ERRCODE ) 
			{
				$NatNonVeg2 = NaturallyNonVeg($AnthVeg);
				$keys = "AnthVeg" . "#" . $AnthVeg."### has been translated by NatNonVeg";
				$herror{$keys}++;
				# if ( $NatNonVeg2 eq ERRCODE )
				# {
				# 	$keys = "AnthVeg" . "#" . $AnthVeg;
				# 	$herror{$keys}++;
				# }	
			}
		}
		
		if(is_missing($NonForAnth))
		{
			$NonForAnth = $NonForAnth2;
		}

		if(is_missing($NatNonVeg))
		{
			$NatNonVeg = $NatNonVeg2;
		}

		$NonForVeg = NonForestedVeg( $NFL, $Height, $AnthVeg );
		if ( $NonForVeg eq ERRCODE ) 
		{
			$keys = "NFL" . "#" . $NFL;
			$herror{$keys}++;
		}

 
		#		if ( $NFLPer eq "" ) {
		#			$CCHigh = UNDEF;
		#			$CCLow  = UNDEF;
		#		}
		#		elsif ( $NFLPer ge 0 ) {
		#				$CCHigh = $NFLPer * 10;
		#				$CCLow  = $NFLPer * 10;
		#		}else {
		#				$CCHigh = ERRCODE;
		#				$CCLow  = ERRCODE;
		#		}
		
		my $UNonForAnth2 = MISSCODE;
		my $UNatNonVeg2 = MISSCODE;
		$UNatNonVeg = NaturallyNonVeg($UNatNon);
		if ( $UNatNonVeg eq ERRCODE ) 
		{
			$UNonForAnth2 = NonForestedAnth($UNatNon);
			#$keys = "UNatNon" . "#" . $UNatNon. "###could be translated by UNonforanth $UNonForAnth2";
			$keys = "UNatNon" . "#" . $UNatNon. "###has been translated by UNonForAnth";
			$herror{$keys}++;
			# if ( $UNonForAnth2 eq ERRCODE )
			# {
			# 	$keys = "UNatNon" . "#" . $UNatNon;
			# 	$herror{$keys}++;
			# }	
		}

		if ( !isempty($UAnthNon)) 
		{
			$UNonForAnth = NonForestedAnth($UAnthNon);
			if ( $UNonForAnth eq ERRCODE ) 
			{
				$UNatNonVeg2 = NaturallyNonVeg($UAnthNon);
				$keys = "UAnthNon" . "#" . $UAnthNon. "###has been translated by UNatNonVeg";
				$herror{$keys}++;
				# if ( $UNatNonVeg2 eq ERRCODE )
				# {
				# 	$keys = "UAnthNon" . "#" . $UAnthNon;
				# 	$herror{$keys}++;
				# }	
			}
		}
		else
		{
			$UNonForAnth = NonForestedAnth($UAnthVeg);
			if ( $UNonForAnth eq ERRCODE ) 
			{
				$UNatNonVeg2 = NaturallyNonVeg($UAnthVeg);
				$keys = "UAnthVeg" . "#" . $UAnthVeg. "###has been translated by UNatNonVeg";
				$herror{$keys}++;
				# if ( $UNatNonVeg2 eq ERRCODE )
				# {
				# 	$keys = "UAnthVeg" . "#" . $UAnthVeg;
				# 	$herror{$keys}++;
				# }	
			}
		}
		if(is_missing($UNonForAnth))
		{
			$UNonForAnth = $UNonForAnth2;
		}

		if(is_missing($UNatNonVeg))
		{
			$UNatNonVeg = $UNatNonVeg2;
		}

		$UNonForVeg = NonForestedVeg( $UNFL, $UHeight, $UAnthVeg );
		if ( $UNonForVeg eq ERRCODE ) 
		{
			$keys = "UNFL" . "#" . $UNFL;
			$herror{$keys}++;
		}

		if( !is_missing($UNatNonVeg) || !is_missing($UNonForAnth) || !is_missing($UNonForVeg) )
        {
            $IsUNFL = 1;
        }
        else 
        {
		    $IsUNFL = 0;
		}

			# ===== Modifiers =====
			$Dist1  = Disturbance( $Mod1,  $Mod1Yr );
			$Dist2  = Disturbance( $Mod2,  $Mod2Yr );
			$Dist3  = Disturbance( $Mod3,  $Mod3Yr );
			$UDist1 = Disturbance( $UMod1, $UMod1Yr );
			$UDist2 = Disturbance( $UMod2, $UMod2Yr );
			$UDist3 = Disturbance( $UMod3, $UMod3Yr );
			
			($Dist1P1, $OR1)  =split(",", $Dist1);
			($Dist2P1, $OR2)  =split(",", $Dist2);
			($Dist3P1, $OR3)  =split(",", $Dist3);
			($UDist1P1, $UR1)  =split(",", $UDist1);
			($UDist2P1, $UR2)  =split(",", $UDist2);
			($UDist3P1, $UR3)  =split(",", $UDist3);

			$Dist1ExtHigh = DisturbanceExtentUpper($Mod1Ext);
			$Dist1ExtLow  = DisturbanceExtentLower($Mod1Ext);
			$Dist2ExtHigh = DisturbanceExtentUpper($Mod2Ext);
			$Dist2ExtLow  = DisturbanceExtentLower($Mod2Ext);

			$Dist3ExtHigh = DisturbanceExtentUpper($Mod3Ext);
			$Dist3ExtLow  = DisturbanceExtentLower($Mod3Ext);
	 
			#if($Mod1 ne "AS" && $Mod1 ne "BD" && $Mod1 ne "CO" && $Mod1 ne "CW" && $Mod1 ne "CY" && $Mod1 ne "DE" && $Mod1 ne "ID" && $Mod1 ne "NC" && $Mod1 ne "OR" && $Mod1 ne "PI" && $Mod1 ne "TL" && $Mod1 ne "UP" && ($Mod1 !~ /\d/ )){
			if ($OR1 =~ ERRCODE || $OR2 =~ ERRCODE || $OR3 =~ ERRCODE ) 
			{
				$keys = "DistYear1--DistYear2--DistYear3#". $Mod1Yr."--".$Mod2Yr."--".$Mod3Yr;$herror{$keys}++;	
			}

			if ($UR1 =~ ERRCODE || $UR2 =~ ERRCODE || $UR3 =~ ERRCODE ) 
			{
				$keys = "UDistYear1--UDistYear2--UDistYear3#". $UMod1Yr."--".$UMod2Yr."--".$UMod3Yr;$herror{$keys}++;	
			}
			if ($Dist1P1 =~ ERRCODE ) 
			{

				if($Illegal_Dist_list{$Mod1}  && (($OR1 ne MISSCODE && $OR1 ne ERRCODE) || (!is_missing($Dist1ExtHigh)))) 
				{
					$Dist1P1="OT"; 
					$Dist1=$Dist1P1.",".$OR1;
				}
				elsif(!$Illegal_Dist_list{$Mod1} && ($Mod1 !~ /\d/ ))
				{
					$keys = "O1 disturbance code#". $Mod1;$herror{$keys}++;	
				}
				elsif(($Mod1 =~ /\d/ ))
				{
					$keys = "O1 disturbance invalid bcse NUMERIC#";$herror{$keys}++;	
				}
				else 
				{
					$keys = "O1 disturbance code-already checked-ILLEGAL#mod-modyear-ext". $Mod1."-".$Mod1Yr."-".$Mod1Ext;$herror{$keys}++;	
				}	
			}

			if ($Dist2P1 =~ ERRCODE)
			{
				if($Illegal_Dist_list{$Mod2}  && (($OR2 ne MISSCODE && $OR2 ne ERRCODE) || (!is_missing($Dist2ExtHigh)))) 
				{
					$Dist2P1="OT"; 
					$Dist2=$Dist2P1.",".$OR2;
				}
				elsif(!$Illegal_Dist_list{$Mod2} && ($Mod2 !~ /\d/ ))
				{
					$keys = "O2 disturbance code#". $Mod2;$herror{$keys}++;	
				}
				elsif(($Mod2 =~ /\d/ )){
					$keys = "O2 disturbance invalid bcse NUMERIC#";$herror{$keys}++;	
				}
				else 
				{
					$keys = "O2 disturbance code-already checked-ILLEGAL#mod-modyear-ext". $Mod2."-".$Mod2Yr."-".$Mod2Ext;$herror{$keys}++;
				}		
			}

			if ($Dist3P1 =~ ERRCODE)
			{
				if($Illegal_Dist_list{$Mod3}  && (($OR3 ne MISSCODE && $OR3 ne ERRCODE) || (!is_missing($Dist3ExtHigh)))) 
				{
					$Dist3P1="OT"; 
					$Dist3=$Dist3P1.",".$OR3;
				}
				elsif(!$Illegal_Dist_list{$Mod3} && ($Mod3 !~ /\d/ ))
				{
					$keys = "O3 disturbance code#". $Mod3;$herror{$keys}++;	
				}
				elsif(($Mod3 =~ /\d/ )){
					$keys = "O3 disturbance invalid bcse NUMERIC#";$herror{$keys}++;	
				}
				else 
				{
					$keys = "O2=3 disturbance code-already checked-ILLEGAL#mod-modyear-ext". $Mod3."-".$Mod3Yr."-".$Mod3Ext;$herror{$keys}++;
				}		
			}

			if ($Dist1ExtHigh eq ERRCODE || $Dist1ExtLow eq ERRCODE || $Dist2ExtHigh eq ERRCODE || $Dist2ExtLow eq ERRCODE) 
			{
				$keys = "disturbance extent#Mod1Ext#" . $Mod1Ext."#Mod2Ext#mod-modyear-ext".$Mod2Ext;
				$herror{$keys}++;		
			}
			
			# debug
			if($CASID eq 'AB_0016_T065R02M6_00000058764'){
				print('AB_0016_T065R02M6_00000058764');
			}
		
			$UDist1ExtHigh = DisturbanceExtentUpper($UMod1Ext);
			$UDist1ExtLow  = DisturbanceExtentLower($UMod1Ext);
			$UDist2ExtHigh = DisturbanceExtentUpper($UMod2Ext);
			$UDist2ExtLow  = DisturbanceExtentLower($UMod2Ext);

			$UDist3ExtHigh = DisturbanceExtentUpper($UMod3Ext);
			$UDist3ExtLow  = DisturbanceExtentLower($UMod3Ext);
			
			if ( $UDist1P1 =~ ERRCODE ) 
			{
				if($Illegal_Dist_list{$UMod1}  && (($UR1 ne MISSCODE && $UR1 ne ERRCODE) || (!is_missing($UDist1ExtHigh)))) {
					$UDist1P1="OT"; 
					$UDist1=$UDist1P1.",".$UR1;
				}
				elsif(!$Illegal_Dist_list{$UMod1} && ($UMod1 !~ /\d/ )){
				$keys = "U1 disturbance code#". $UMod1;$herror{$keys}++;$herror{$keys}++;
				}
				elsif(($UMod1 =~ /\d/ )){
				$keys = "U1 disturbance invalid bcse NUMERIC#";$herror{$keys}++;
				}
				else {$keys = "U1 disturbance code-already checked-ILLEGAL#mod-modyear-ext". $UMod1."-".$UMod1Yr."-".$UMod1Ext;$herror{$keys}++;}
						
			}
			if ( $UDist2P1 =~ ERRCODE ) {
				if($Illegal_Dist_list{$UMod2}  && (($UR2 ne MISSCODE && $UR2 ne ERRCODE) || (!is_missing($UDist2ExtHigh)))) {
					$UDist2P1="OT"; 
					$UDist2=$UDist2P1.",".$UR2;
				}
				elsif(!$Illegal_Dist_list{$UMod2} && ($UMod2 !~ /\d/ )){
				$keys = "U2 disturbance code#". $UMod2;$herror{$keys}++;
				}
				elsif(($UMod2 =~ /\d/ )){
				$keys = "U2 disturbance invalid bcse NUMERIC#";$herror{$keys}++;
				}
				else {$keys = "U2 disturbance code-already checked-ILLEGAL#mod-modyear-ext". $UMod2."-".$UMod2Yr."-".$UMod2Ext;$herror{$keys}++;}
						
			}

			if ( $UDist3P1 =~ ERRCODE ) {
				if($Illegal_Dist_list{$UMod3}  && (($UR3 ne MISSCODE && $UR3 ne ERRCODE) || (!is_missing($UDist3ExtHigh)))) {
					$UDist3P1="OT"; 
					$UDist3=$UDist3P1.",".$UR3;
				}
				elsif(!$Illegal_Dist_list{$UMod3} && ($UMod3 !~ /\d/ )){
				$keys = "U3 disturbance code#". $UMod3;$herror{$keys}++;
				}
				elsif(($UMod3 =~ /\d/ )){
				$keys = "U3 disturbance invalid bcse NUMERIC#";$herror{$keys}++;
				}
				else {$keys = "U3 disturbance code-already checked-ILLEGAL#mod-modyear-ext". $UMod3."-".$UMod3Yr."-".$UMod3Ext;$herror{$keys}++;}
						
			}
			if ($UDist1ExtHigh eq ERRCODE || $UDist1ExtLow eq ERRCODE || $UDist2ExtHigh eq ERRCODE || $UDist2ExtLow eq ERRCODE) {
				$keys = "understory disturbance extent#Mod1Ext#" . $UMod1Ext."#Mod2Ext#".$UMod2Ext;
				$herror{$keys}++;		
			}
				
			if(defined($AnthNon) &&  uc($AnthNon) eq "AIL"){
				$Dist1ExtHigh = 100;
				$Dist1ExtLow = 95 ;
				#$Dist1 = "CO";
				$Dist1P1 = "CO";
				$Dist1= $Dist1P1.",".$OR1;
				$keys = "BK check error type 1";
				$herror{$keys}++;	
			}
			if(defined($UAnthNon) && uc($UAnthNon) eq "AIL"){
				$UDist1ExtHigh = 100;
				$UDist1ExtLow = 95 ;
				#$Dist1 = "CO" ;
				$UDist1P1= "CO";
				$UDist1=$UDist1P1.",".$UR1;
				$keys = "BK check error type 2";
				$herror{$keys}++;	
			}

			$Dist1 = $Dist1 . "," . $Dist1ExtHigh . "," . $Dist1ExtLow;
			$Dist2 = $Dist2 . "," . $Dist2ExtHigh . "," . $Dist2ExtLow;
			$Dist3 = $Dist3 . "," . $Dist3ExtHigh . "," . $Dist3ExtLow;

			$UDist1 = $UDist1 . "," . $UDist1ExtHigh . "," . $UDist1ExtLow;
			$UDist2 = $UDist2 . "," . $UDist2ExtHigh . "," . $UDist2ExtLow;
			$UDist3 = $UDist3 . "," . $UDist3ExtHigh . "," . $UDist3ExtLow;

			# $Dist  = $Dist1 . "," . $Dist2 . ",". pad(UNDEF, 4);
			# $UDist = $UDist1 . "," . $UDist2 . ",". pad(UNDEF, 4);
			$Dist  = $Dist1 . "," . $Dist2 . ",".$Dist3;
			$UDist = $UDist1 . "," . $UDist2 . ",".$Dist3;

			my ($prod_for, $lyr_poly1) = productive_code ($Sp1, $CCHigh , $CCLow , $HeightHigh , $HeightLow,  $Density);
			if($lyr_poly1)
			{
				$SpeciesComp ="XXXX MISS,0,XXXX MISS,0,XXXX MISS,0,XXXX MISS,0,XXXX MISS,0,XXXX MISS,0,XXXX MISS,0,XXXX MISS,0,XXXX MISS,0,XXXX MISS,0";
				#$keys="###check artificial lyr1 on #".$Sp1;
				#$herror{$keys}++; 
			}	
			
			($Dist1P1, $OR1)  =split(",", $Dist1);
			if ($Dist1P1  eq "CO")
			{
				$prod_for="PF";
				$lyr_poly1=1;
			}


			my ($Uprod_for, $lyr_poly2) = productive_code ($USp1, $UCCHigh , $UCCLow , $UHeightHigh , $UHeightLow,  $UDensity);
			if($lyr_poly2)
			{
				$USpeciesComp ="XXXX MISS,0,XXXX MISS,0,XXXX MISS,0,XXXX MISS,0,XXXX MISS,0,XXXX MISS,0,XXXX MISS,0,XXXX MISS,0,XXXX MISS,0,XXXX MISS,0";
				#$keys="###check artificial lyr1 on #".$USp1;
				#$herror{$keys}++; 
			}	
			($UDist1P1, $UR1)  =split(",", $UDist1);
			if ($UDist1P1  eq "CO")
			{
				$Uprod_for="PF";
				$lyr_poly2=1;
			}

			if($CASID =~ /AB_0026/ || $CASID =~ /AB_0027/ || $CASID =~ /AB_0028/ )
			{
				$CASphotoYear= UNDEF;
			}
			else 
			{
				$CASphotoYear = Photo($PHOTOYEAR);
				if ( $CASphotoYear eq "-1") 
				{
					if(isempty($PHOTOYEAR))
					{
						$PHOTOYEAR = "NULL OR EMPTYVAL";
					}

					$keys = "PHOTOYEAR" . "#" . $PHOTOYEAR;
					$herror{$keys}++;
					$CASphotoYear=ERRCODE;
				}
			}
		
			# ===== Output inventory info for layer 1 =====
			#SGC Define a test for NFL
            if( !is_missing($NatNonVeg) || !is_missing($NonForAnth) || !is_missing($NonForVeg) )
            {
                $IsNFL = 1;
            }
            else 
            {
		     	$IsNFL = 0;
			}
		
			if($StandStructureCode ne "H" && $StandStructureCode ne "C" )
			{
		       	$UStandStructureVal = UNDEF;   
				$StandStructureVal = UNDEF;            
			}	

		if(isempty($StandStructureCode))
		{
			$StandStructureCode ="S";
		}


		given ($StandStructureCode) 
		{
			when ( [ "S", "C", MISSCODE.""] ) #simplest way to convert misscode to text
			{
				$CAS_Record =
					$CASID . "," . $PolyNum . ","
					. $StandStructureCode . ",1,"
					. $IdentifyID . ","
					  . $MapSheetID . ","
					  . $Area . ","
					  . $Perimeter . ","
					  . $Area . ","
					  . $CASphotoYear;
				print CASCAS $CAS_Record . "\n";
				
	
				#forested
				#SGC There are cases where some source data sets 
				#	assign species codes such as SO or SC for NFL polygons
				#	This is not standards compliant, and no .lyr record should
				#     be emitted. The test on $Sp1 ne "" is insufficient, therefore.
		
				# if ( !isempty($Sp1) && !$CREATE_NFL_LYR	 )
				if ( (!isempty($Sp1) && !$CREATE_NFL_LYR	) || $lyr_poly1 )
				{
						$LYR_Record1 = $CASID . "," . $SMR . "," . $StandStructureVal . ",1,1";    # LAYER and LAYER_RANK 
						$LYR_Record2 = $CCHigh . "," . $CCLow . "," . $HeightHigh . "," . $HeightLow . "," . $prod_for."," . $SpeciesComp;
					 	$LYR_Record3 = $OriginHigh . ",". $OriginLow . "," . $SiteClass . "," . $SiteIndex;
						$Lyr_Record =  $LYR_Record1 . "," . $LYR_Record2 . "," . $LYR_Record3;
						print CASLYR $Lyr_Record . "\n";

						if ($Sp1 eq "SC" || $Sp1 eq "SO")
						{
							$keys="species code SC or  SC when struct = S or C #see species".$Sp1. "#see struct $StandStructureCode"."see lyrpoly  $lyr_poly1 ";
							$herror{$keys}++; 
						}
				}
	
				#non-forested
				elsif ( $IsNFL )
				{
						$NFL_Record1 =
						    $CASID . "," . $SMR . ","
						  . $StandStructureVal
						  . ",1,1";    # LAYER and LAYER_RANK
						$NFL_Record2 =
						  $CCHigh . "," . $CCLow . "," . UNDEF . "," . UNDEF;
						$NFL_Record3 =
						  $NatNonVeg . "," . $NonForAnth . "," . $NonForVeg;
						$NFL_Record =
						  $NFL_Record1 . "," . $NFL_Record2 . "," . $NFL_Record3;
						print CASNFL $NFL_Record . "\n";


						# if ($Sp1 eq "SC" || $Sp1 eq "SO")
						# {
						# 	$keys="created  nfl of layer 1 when struct = S or C  $CREATE_UNFL_LYR (logged only  for further investigations)";
						# 	$herror{$keys}++; 
						# }
				}
		
				#Disturbance
				if ( !isempty($Mod1) && !is_missing($Mod1) &&$Dist1P1 !~ ERRCODE) 
				{
					$DST_Record = $CASID . "," . $Dist.",1";
					print CASDST $DST_Record . "\n";
				}
		
				#Ecological
				if ( $Wetland ne MISSCODE ) 
				{
						$Wetland = $CASID . "," . $Wetland ."-";
						print CASECO $Wetland . "\n";
				}
			}

				# 2 layers and only 2 lyrs
			when(["H", "M"])
			{
					$CAS_Record =
				    $CASID . "," . $PolyNum . ","
  				  . $StandStructureCode . ",2,"
				  . $IdentifyID . ","
				  . $MapSheetID . ","
				  . $Area . ","
				  . $Perimeter . ","
				  . $Area . ","
				  . $CASphotoYear;
					print CASCAS $CAS_Record . "\n";
	
				#SGC Repeat previous test on IsNFL to ensure
				#that .lyr records not emitted for NFL
	
				if ( (!isempty($Sp1)  && !$CREATE_NFL_LYR	) || $lyr_poly1 ) 
				{
						$LYR_Record1 =
						    $CASID . "," . $SMR . ","
						  . $StandStructureVal
						  . ",1,1";    # LAYER and LAYER_RANK . ","  . $UnprodFor;
						$LYR_Record2 =
						    $CCHigh . "," . $CCLow . ","
						  . $HeightHigh . ","
						  . $HeightLow . ","
						  . $prod_for.","
						  . $SpeciesComp;
						$LYR_Record3 =
						    $OriginHigh . ","
						  . $OriginLow . ","
						  . $SiteClass . ","
						  . $SiteIndex;
						$Lyr_Record =
						  $LYR_Record1 . "," . $LYR_Record2 . "," . $LYR_Record3;
						print CASLYR $Lyr_Record . "\n";

						if ($Sp1 eq "SC" || $Sp1 eq "SO")
						{
							$keys="species code SC or  SC when struct = H or M #see species".$Sp1. "#see struct $StandStructureCode"."see lyrpoly  $lyr_poly1 ";
							$herror{$keys}++; 
						}
				}
	
				elsif ($IsNFL )
				{
						$NFL_Record1 =
						    $CASID . "," . $SMR . ","
						  . $StandStructureVal
						  . ",1,1";
						$NFL_Record2 =
						  $CCHigh . "," . $CCLow . "," . UNDEF . "," . UNDEF;
						$NFL_Record3 =
						  $NatNonVeg . "," . $NonForAnth . "," . $NonForVeg;
						$NFL_Record =
						  $NFL_Record1 . "," . $NFL_Record2 . "," . $NFL_Record3;
						print CASNFL $NFL_Record . "\n";
						# if ($Sp1 eq "SC" || $Sp1 eq "SO")
						# {
						# 	$keys="created  nfl of layer 1 when struct = H or M  $CREATE_UNFL_LYR (logged only  for further investigations)";
						# 	$herror{$keys}++; 
						# }
				}
				if ( !isempty($Mod1) && !is_missing($Mod1) && $Dist1P1 !~ ERRCODE ) {
						$DST_Record = $CASID . "," . $Dist.",1";
						print CASDST $DST_Record . "\n";
				}
		
					#Ecological
				if ( $Wetland ne MISSCODE ) {
						$Wetland = $CASID . "," . $Wetland ."-";
						print CASECO $Wetland . "\n";
				}
	
					#Under story
		
					#SGC repeat test on NFL to prevent .lry records for 
					#cases where SLP violates the standard.
		
				if ( (!isempty($USp1) && !$CREATE_UNFL_LYR	) || $lyr_poly2) 
				{ 
						#this dropped -. $UStandStructureCode 
						$LYR_Record1 =
						    $CASID . "," . $USMR . ","
						  . $UStandStructureVal
						  . ",2,2";    # LAYER and LAYER_RANK  . ","  . $UUnprodFor;
						$LYR_Record2 =
						    $UCCHigh . "," . $UCCLow . ","
						  . $UHeightHigh . ","
						  . $UHeightLow . ","
	 					  . $Uprod_for.","
						  . $USpeciesComp;
						$LYR_Record3 =
						    $UOriginHigh . ","
						  . $UOriginLow . ","
						  . $USiteClass . ","
						  . $USiteIndex; 
						$Lyr_Record =
						  $LYR_Record1 . "," . $LYR_Record2 . "," . $LYR_Record3;
						print CASLYR $Lyr_Record . "\n";

						if ($USp1 eq "SC" || $USp1 eq "SO")
						{
							$keys="understory species code SC or  SC when struct = H or M #see species".$USp1. "#see struct $StandStructureCode"."see lyrpoly  $lyr_poly2 ";
							$herror{$keys}++; 
						}
					}
				elsif (   $IsUNFL)
				{
						#this dropped -. $UStandStructureCode 
						$NFL_Record1 =
						    $CASID . "," . $SMR . ","
						  . $UStandStructureVal
						  . ",2,2";    # LAYER and LAYER_RANK
						$NFL_Record2 =
						    $UCCHigh . "," . $UCCLow . ","
						  . UNDEF . ","
						  . UNDEF;
						$NFL_Record3 =
						  $UNatNonVeg . "," . $UNonForAnth . "," . $UNonForVeg;
						$NFL_Record =
						  $NFL_Record1 . "," . $NFL_Record2 . "," . $NFL_Record3;
						print CASNFL $NFL_Record . "\n";
						# if ($USp1 eq "SC" || $USp1 eq "SO")
						# {
						# 	$keys="created  nfl of layer 2 when struct = H or M  $CREATE_UNFL_LYR (logged only  for further investigations)";
						# 	$herror{$keys}++; 
						# }
					}
				
					#18-09-2012 at this time understory disturbance is not reported
					#if ( $UMod1 ne "" && $UDist1P1 !~ ERRCODE) {
						#$DST_Record = $CASID . "," . $UDist;
						#print CASDST $DST_Record . "\n";
					#}

					#july 2014 UDist is now reported
				if ( !isempty($UMod1) && !is_missing($UMod1) && $UDist1P1 !~ ERRCODE) 
				{
						$DST_Record = $CASID . "," . $UDist.",2";
						print CASDST $DST_Record . "\n";
				}
			}
			default
			{
				$keys = " structurecode  - RECORD will still be added to the .cas file " ;
				$herror{$keys}++;
				# this is added to avoid missing information about these polygones
				$CAS_Record =
					$CASID . "," . $PolyNum . ","
					. ERRCODE . ",1,"
					. $IdentifyID . ","
					  . $MapSheetID . ","
					  . $Area . ","
					  . $Perimeter . ","
					  . $Area . ","
					  . $CASphotoYear;
				print CASCAS $CAS_Record . "\n";
			}
		}
	}

	$csv->eof or $csv->error_diag();
	close $ABinv;
	
	foreach my $k (sort {lc($a) cmp lc($b)} keys %$spfreq)
	{
		$_ = $k;
		tr/a-z/A-Z/;
		my $upk = $_;
	 	print SPERRSFILE "cumulative frequency of species " ,$upk,  " is ", $spfreq->{$k},"\n";
		#print "invalid code " ,$k,  " found ", $herror{$k}," times\n";
  	}

	#print ERRS "---" . $AB_File ." begin bug report:\n";
	foreach my $k ( keys %herror ) {
		print ERRS "invalid code ", $k, " found ", $herror{$k}, " times\n";
	}

	#close(ABinv);
	close(CASHDR);
	close(CASCAS);
	close(CASLYR);
	close(CASNFL);
	close(CASDST);
	close(CASECO);
	close(SPECSLOGFILE); 
	#close(INFOHDR);
	#print ERRS "---" . $AB_File ." finished---\n\n";
	close(ERRS);
	close(SPERRSFILE);

}

1;

