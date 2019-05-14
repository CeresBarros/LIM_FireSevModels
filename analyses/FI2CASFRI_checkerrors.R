## HOW MANY NON FOREST BEFORE CASFRI

## SASKATCWEWAN
## note that orignal SK shp had many data mismatches
table(saskatchewanfires_prefireMelt$TYPE[saskatchewanfires_prefireMelt$LAYER == "1"])
# BSH  FOR  NFA  OMS  OTH  TMS  WAT
# 46 3110    1  185    7 1032  203

## no. non.forested polygons
pixNonFor <- unique(saskatchewanfires_prefireMelt$P_ID[!saskatchewanfires_prefireMelt$TYPE %in% c("FOR", "NFA")])
length(pixNonFor)
# [1] 1473
pixWater <-  unique(saskatchewanfires_prefireMelt$P_ID[saskatchewanfires_prefireMelt$TYPE %in% c("WAT")])
length(pixWater)

table(saskatchewanfires_prefireMeltCASFRI$WETLAND_CLASS)
table(saskatchewanfires_prefireMeltCASFRI$NON_FORESTED_VEG)
table(saskatchewanfires_prefireMeltCASFRI$NON_FORESTED_ANTHRO)
table(saskatchewanfires_prefireMeltCASFRI$NATURALLY_NON_VEG)

pixNonForCAS <- unique(saskatchewanfires_prefireMeltCASFRI$P_ID[
  (!is.na(saskatchewanfires_prefireMeltCASFRI$WETLAND_CLASS) &
     !saskatchewanfires_prefireMeltCASFRI$WETLAND_VEG_MOD %in% "F") |
  !is.na(saskatchewanfires_prefireMeltCASFRI$NON_FORESTED_VEG) |
    !is.na(saskatchewanfires_prefireMeltCASFRI$NATURALLY_NON_VEG) |
    !is.na(saskatchewanfires_prefireMeltCASFRI$NON_FORESTED_ANTHRO)])
length(pixNonForCAS)

pixWaterCAS <- unique(saskatchewanfires_prefireMeltCASFRI$P_ID[
  saskatchewanfires_prefireMeltCASFRI$NATURALLY_NON_VEG %in% "WA"])
length(pixWaterCAS)
length(setdiff(pixWaterCAS, pixWater)) == 0 & length(setdiff(pixWater, pixWaterCAS)) == 0  ## TRUE is good

## for non forested TYPE treed wetlands
saskatchewanfires_prefireMelt[saskatchewanfires_prefireMelt$P_ID %in% setdiff(pixNonForCAS, pixNonFor),]
saskatchewanfires_prefireMeltCASFRI[saskatchewanfires_prefireMeltCASFRI$P_ID %in% setdiff(pixNonForCAS, pixNonFor),]

saskatchewanfires_prefireMelt[saskatchewanfires_prefireMelt$P_ID %in% ,]
saskatchewanfires_prefireMeltCASFRI[saskatchewanfires_prefireMeltCASFRI$P_ID %in% setdiff(pixWaterCAS, pixWater),]


## ALBERTA
table(albertafires1_prefire$NAT_NON)
# NMC NMR NMS NWF NWL NWR
# 12   6   5  36   8  44

table(albertafires1_prefireMelt$NAT_NON[albertafires1_prefireMelt$LAYER == 1])
# NMC NMR NMS NWF NWL NWR
# 12   6   5  36   8  44

table(albertafires1_prefireMeltCASFRI$NATURALLY_NON_VEG[albertafires1_prefireMeltCASFRI$LAYER == 1])
# EX   FL   LA   NA   RI   RK   SA   SD   SI   WS <NA>
#   12   36    8    0   44    6    0    0    0    5 8152

table(albertafires1_prefire$NFL)
# BR  HG  SC  SO
# 1 104 406  94

table(albertafires1_prefireMelt$NFL[albertafires1_prefireMelt$LAYER == 1])
# BR  HG  SC  SO
# 1 104 406  94

table(albertafires1_prefireMeltCASFRI$NON_FORESTED_VEG[albertafires1_prefireMeltCASFRI$LAYER == 1])
# BR   HF   HG   NA   SL   ST <NA>
#   1    0  104    0  181  319    0

table(albertafires1_prefire$UNAT_NON)
# < table of extent 0 >

table(albertafires1_prefire$ANTH_NON)
# AIF AIH AII ASR
# 1   5   6   1

table(albertafires1_prefireMelt$ANTH_NON[albertafires1_prefireMelt$LAYER == 1])
# AIF AIH AII ASR
# 1   5   6   1

table(albertafires1_prefireMeltCASFRI$NON_FORESTED_ANTHRO[albertafires1_prefireMeltCASFRI$LAYER == 1])

table(albertafires1_prefire$UANTH_NON)
# < table of extent 0 >


## check for mismatching values - TRUE is good
is.na(unique(albertafires1_prefire$NAT_NON[!is.na(albertafires1_prefire$NFL)]))
is.na(unique(albertafires1_prefire$NAT_NON[!is.na(albertafires1_prefire$ANTH_NON)]))
is.na(unique(albertafires1_prefire$NAT_NON[!is.na(albertafires1_prefire$ANTH_VEG)]))
is.na(unique(albertafires1_prefire$NFL[!is.na(albertafires1_prefire$ANTH_NON)]))
## ANTH_VEG = CPR requires NFL = SO/SC
unique(albertafires1_prefire$NFL[which(albertafires1_prefire$ANTH_VEG == "CPR")]) %in% c("SO", "SC")
is.na(unique(albertafires1_prefire$NFL[!is.na(albertafires1_prefire$ANTH_VEG) & albertafires1_prefire$ANTH_VEG != "CPR"]))

table(albertafires2_prefire$NAT_NON)
# < table of extent 0 >

table(albertafires2_prefireMelt$NAT_NON[albertafires2_prefireMelt$LAYER == 1])
# < table of extent 0 >

table(albertafires2_prefire$NFL)
# BR  HG  SC
# 13 103 256

table(albertafires2_prefireMelt$NFL[albertafires2_prefireMelt$LAYER == 1])
# BR  HG  SC
# 13 103 256

table(albertafires2_prefireMeltCASFRI$NON_FORESTED_VEG[albertafires2_prefireMeltCASFRI$LAYER == 1])
#   BR   HF   HG   NA   SL   ST <NA>
#   13    0  103    0   89  167    0

table(albertafires2_prefire$UNAT_NON)
# < table of extent 0 >

table(albertafires2_prefire$ANTH_NON)
# < table of extent 0 >

table(albertafires2_prefireMelt$ANTH_NON[albertafires2_prefireMelt$LAYER == 1])
# < table of extent 0 >

table(albertafires2_prefire$UANTH_NON)
# < table of extent 0 >

## check for mismatching values - TRUE is good
is.na(unique(albertafires2_prefire$NAT_NON[!is.na(albertafires2_prefire$NFL)]))
is.na(unique(albertafires2_prefire$NAT_NON[!is.na(albertafires2_prefire$ANTH_NON)]))
is.na(unique(albertafires2_prefire$NAT_NON[!is.na(albertafires2_prefire$ANTH_VEG)]))
is.na(unique(albertafires2_prefire$NFL[!is.na(albertafires2_prefire$ANTH_NON)]))
## ANTH_VEG = CPR requires NFL = SO/SC
unique(albertafires2_prefire$NFL[which(albertafires2_prefire$ANTH_VEG == "CPR")]) %in% c("SO", "SC")
is.na(unique(albertafires2_prefire$NFL[!is.na(albertafires2_prefire$ANTH_VEG) & albertafires2_prefire$ANTH_VEG != "CPR"]))
