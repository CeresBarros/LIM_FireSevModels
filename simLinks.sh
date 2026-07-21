## Create simLinks for large folders (fire-severity models project)

#mkdir -p /mnt/storage/cbarros/LIM_FireSevModels/analyses

## move folders to storage
rsync -a /home/cbarros/GitHub/LIM_FireSevModels/analyses/cache /mnt/storage/cbarros/LIM_FireSevModels/analyses
rsync -a /home/cbarros/GitHub/LIM_FireSevModels/analyses/DAfires_expAnalyses_files /mnt/storage/cbarros/LIM_FireSevModels/analyses
rsync -a /home/cbarros/GitHub/LIM_FireSevModels/analyses/DAfires_expAnalyses_cache /mnt/storage/cbarros/LIM_FireSevModels/analyses
rsync -a /home/cbarros/GitHub/LIM_FireSevModels/analyses/fireDataJoins /mnt/storage/cbarros/LIM_FireSevModels/analyses
rsync -a /home/cbarros/GitHub/LIM_FireSevModels/analyses/fireDataSummary /mnt/storage/cbarros/LIM_FireSevModels/analyses
rsync -a /home/cbarros/GitHub/LIM_FireSevModels/analyses/FireEvents /mnt/storage/cbarros/LIM_FireSevModels/analyses
rsync -a /home/cbarros/GitHub/LIM_FireSevModels/analyses/firesInFMAs /mnt/storage/cbarros/LIM_FireSevModels/analyses

## after checking all is good remove the contents of the folders before creating the links

## create simLinks
ln -s /mnt/storage/cbarros/LIM_FireSevModels/analyses/cache ~/GitHub/LIM_FireSevModels/analyses/cache
ln -s /mnt/storage/cbarros/LIM_FireSevModels/analyses/DAfires_expAnalyses_files /home/cbarros/GitHub/LIM_FireSevModels/analyses/DAfires_expAnalyses_files
ln -s /mnt/storage/cbarros/LIM_FireSevModels/analyses/DAfires_expAnalyses_cache /home/cbarros/GitHub/LIM_FireSevModels/analyses/DAfires_expAnalyses_cache
ln -s /mnt/storage/cbarros/LIM_FireSevModels/analyses/fireDataJoins /home/cbarros/GitHub/LIM_FireSevModels/analyses/fireDataJoins
ln -s /mnt/storage/cbarros/LIM_FireSevModels/analyses/fireDataSummary /home/cbarros/GitHub/LIM_FireSevModels/analyses/fireDataSummary
ln -s /mnt/storage/cbarros/LIM_FireSevModels/analyses/FireEvents /home/cbarros/GitHub/LIM_FireSevModels/analyses/FireEvents
ln -s /mnt/storage/cbarros/LIM_FireSevModels/analyses/firesInFMAs /home/cbarros/GitHub/LIM_FireSevModels/analyses/firesInFMAs
