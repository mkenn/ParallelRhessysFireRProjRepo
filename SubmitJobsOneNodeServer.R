#######
# run sets of parallel MC RHESSys-Fire runs
# on multicore server (rather than a multinode-multi-core
# super computer)
#######
########
# writes then submits PBS scripts
# have a dummy PBS script to which the final line with
# the correct arguments is appended
########
# this script can be run using R
# in the rhessys directory
# name of template script
total.mc.reps<-150
# number of MC replicates at once 
# this is the number of server cores you
# believe will be available for this set
iter.mc<-50
workspace.pre<-"BCResultsNoEffects" # for the workspace with aggregated results
outPre<-"nsfTestMultIter_basin" # for the output file itself
outPath<-"../output/nsf" # and the directory where the output file should go
filterPath<-"../output/filters" # path to the output filter iteslf
filterName<-"nsf_filter"
# which output variables do you want to keep and at what level?
basin.var<-c("stratum.cs.totalc", "stratum.cs.net_psn", "stratum.cs.nppcum", "patch.litter_cs.totalc", "patch.litter_cs.litr1c", 
             "patch.litter_cs.litr2c","patch.litter_cs.litr3c","patch.litter_cs.litr4c", "patch.cdf.decomp_w_scalar", "patch.cdf.decomp_t_scalar",
             "patch.cdf.cwdc_to_litr2c", "patch.cdf.cwdc_to_litr3c", "patch.cdf.cwdc_to_litr4c", "stratum.cs.cwdc", "patch.fire.pet", "patch.fire.et", 
             "patch.fire.understory_et", "patch.fire.understory_pet", "patch.rootzone.S", "zone.metv.vpd_day", 
             "zone.metv.vpd_night", "patch.snow_stored", "patch.snowpack.water_depth", "patch.snowpack.water_equivalent_depth")
save.image(file="CurrentBatchSettings.RData")
# loop from one to the total number of MC sets
for(k in 1:(total.mc.reps/iter.mc)) 
{
  # what is the first rep id for the current set
  low.arg<-k*iter.mc-iter.mc+1
  # what ist he last rep id for the current set
  high.arg<-k*iter.mc
  # the current command call
  cur.call<-paste("Rscript --vanilla ExecuteMCRepsParallel.R",low.arg,high.arg,sep=" ")

  # execute the current call
  system(cur.call)
  # I believe this R session will stay open until 
  # all runs are complete, so this should be executed
  # from a remote shell screen
}
