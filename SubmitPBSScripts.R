########
# writes then submits PBS scripts
# have a dummy PBS script to which the final line with
# the correct arguments is appended
########
# this script can be run using R
# in the rhessys directory
# name of template script
pbs.script.name<-"PBSScriptTemplate"
# total number of MC replicates
total.mc.reps<-20
# number of MC replicates per job (one job per node)
iter.mc<-4
# loop from one to the total number of jobs submitted
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
