########
# writes then submits PBS scripts
# have a dummy PBS script to which the final line with
# the correct arguments is appended
# This script also sets global settings across all runs
########
# this script can be run using R
# in the rhessys directory
# name of template script
pbs.script.name<-"PBSScriptTemplate"
# total number of MC replicates
total.mc.reps<-200
# number of MC replicates per job (one job per node)
iter.mc<-4
workspace.pre<-"BCResultsPart"
outPre<-"BCbasin30mFire_su"

# and the variables to keep for all runs
# Below are variables to keep from rhessys basin output
# the character strings should match correct RHESSys variable names
basin.var=c("patch.lai","patch.litter_cs.totalc","patch.streamflow","stratum.cs.cwdc") 
# below are variables to keep from basin growth output
# the character strings should match desired columns in the file
# grow.var=c("understory_leafc","understory_stemc","understory_biomassc","understory_height", #
#            "overstory_leafc","overstory_stemc","overstory_biomassc","overstory_height")

# loop from one to the total number of jobs submitted
save.image(file="CurrentBatchSettings.RData")
for(k in 1:(total.mc.reps/iter.mc)) 
{
  low.arg<-k*iter.mc-iter.mc+1
  high.arg<-k*iter.mc
  cur.pbs.script<-paste(pbs.script.name,k,sep="")
  # copy the script template
  system(paste("cp ",pbs.script.name," ",cur.pbs.script,sep=""))
  
  write(paste("Rscript --vanilla ExecuteMCRepsParallel.R",low.arg,high.arg,sep=" "),
        append=TRUE,file=cur.pbs.script)
  # submit the job
  system(paste("qsub ",cur.pbs.script,sep=""))
}
