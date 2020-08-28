#########
# Process and aggregate multiple MC runs from different nodes
# in same directory
#########
# this workspace contains total.mc.reps,iter.mc
# and workspace.pre
load("CurrentBatchSettings.RData")
cur.results<-list()
for(k in 1:(total.mc.reps/iter.mc)) 
{
  file.id<-k*iter.mc-iter.mc+1 # this is how the RData files are marked
  load(paste(workspace.pre,file.id,
           ".RData",sep="")) # this will read in the all.results list. 
       # this is the same named object, so will overwrite every time
  if(k==1)
  {
    cur.results$fire.results<-all.results$fire.results # monthly
    cur.results$rhessys.results<-all.results$rhessys.results # daily
  }
  else
  {
    cur.results$fire.results<-rbind(cur.results$fire.results,
                                    all.results$fire.results) # monthly
    cur.results$rhessys.results<-rbind(cur.results$rhessys.results,
                                       all.results$rhessys.results) # daily
  }
}
# from here you can do analysis
# functions to process annual and montly summaries 
# will be forthcoming
         
  
