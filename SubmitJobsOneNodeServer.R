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
total.mc.reps<-200
# number of MC replicates at once 
# this is the number of server cores you
# believe will be available for this set
iter.mc<-50
workspace.pre<-"BCResultsPart"
outPre<-"BCbasin30mFire_su"
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
