# take as arguments the first and last in sequence
# for the MC reps
args=commandArgs(trailingOnly = TRUE)
if(length(args)<2)
{
  stop("ERROR: Needs two arguments",call.=FALSE)
}
#
# source the function that runs RHESSys
source("runFireMC_FN.R")
########
# first set up the default and header files
# for the current set of MC reps. These should
# be customized for individual applications
outPre="BCbasin30m_su" # prefix for rhessys output files
# Below are variables to keep from rhessys basin output
# the character strings should match desired columns in the file
basin.var=c("lai","litrc","streamflow") 
# below are variables to keep from basin growth output
# the character strings should match desired columns in the file
grow.var=c("understory_leafc","understory_stemc","understory_biomassc","understory_height", #
           "overstory_leafc","overstory_stemc","overstory_biomassc","overstory_height")
# Below are the required components of the RHESSys commandline
# note that the world_hdr_file is just the prefix
# that will be updated by the function. Use the same prefix *.hdr,
# where the prefix is * before .hdr
rhessys.script=list(rhessys_version="~/RHESSysGit/RHESSys/rhessys/rhessys7.2",
                    tec_file="../tecfiles/tec.su",
                    world_file="../worldfiles/BCbasin30mSUfire.world",
                    world_hdr_file="../worldfiles/BCbasin30mFire",
                    flow_file="../flowtables/BCbasin30m.flow",
                    start_date="1941 10 1 1",
                    end_date="1945 10 1 1",
                    command_options=c("-s 3.107846 291.838599 -sv 3.107846 291.838599 -svalt 1.326919 0.797249 -gw 0.188211 0.299011 -b -g -vmort_off -firespread 30 ../auxdata/patchGrid.txt ../auxdata/DemGrid.txt"))
# this vector defines the number of default files
# for basin, hillslope,zone,patch,landuse,canopy_strata,
# fire, and base_stations, respectively
n.defs=c(basin=1,hillslope=1,zone=1,patch=2,
         landuse=1,canopy_strata=4,fire=1,base_stations=1)
# give the defaut filenames in a list
# the names here should match their names in the header file,
# e.g., basin_default_filename requires basin below
def.names=list(basin="../defs/basin_p301.def",
               hillslope="../defs/hill_p301.def",
               zone="../defs/zone_p301.def",
               patch=c("../defs/soil_forestshrub.def",
                       "../defs/soil_shrubonly.def"),
               landuse="../defs/lu_p301.def",
               canopy_strata=c("../defs/veg_p301_conifer_mod.def",
                               "../defs/veg_p301_shrub_understory.def",
                               "../defs/veg_rs_shrub_only.def",
                               "../defs/veg_nonveg.def"),
               fire="../defs/fireBC",
               base_stations="../clim/Grove_lowprov_clim.base")
#               base_stations="../clim/Grove_lowprov_clim.base")
# how many MC reps per node? Here we assume 4 replicates,
# each of which will take 9 omp threads for a total of
# 36 cpus per job
n.mc<-4 
iter.mc.reps<-seq(as.integer(args[1]),as.integer(args[2]),1)
# for every MC replicate run from the same folder, we need
# a unique fire default file, which requires a unique header
# file.
# first we will create these for all of total MC replicates
# then we will run it in sets of iter.mc.reps
all.list<-list()
for(i in 1:length(iter.mc.reps))
{
  Rep<-iter.mc.reps[i]
  hdr.input<-NA
  for(k in 1:length(n.defs))
  {
    if(is.na(hdr.input))
    {
      hdr.input<-paste(n.defs[k],"\t","num_",names(def.names)[k],"_files","\n",
                       def.names[[k]][1],"\t",names(def.names)[k],"_default_filename",sep="")
    }
    else
    {
      if(names(def.names)[k]=="fire")
      {
        hdr.input<-paste(hdr.input,"\n",n.defs[k],"\t","num_",names(def.names)[k],"_files","\n",def.names[[k]][1],
                         Rep,".def  fire_default_filename",sep="")
        
      }
      else
      {
        hdr.input<-paste(hdr.input,"\n",n.defs[k],"\t","num_",names(def.names)[k],"_files","\n",
                         def.names[[k]][1],"\t",names(def.names)[k],"_default_filename",sep="")
        if(n.defs[k]>1)
        {
          for(j in 2:n.defs[k])
          {
            hdr.input<-paste(hdr.input,"\n",def.names[[k]][j],"\t",names(def.names)[k],"_default_filename",sep="")
          }
        }
      }
    }
  }
  # now write the header to the worldfiles directory
  # and name by Rep
  world_hdr_file <- paste(rhessys.script$world_hdr_file,Rep,".hdr",sep="")
    
  write(hdr.input,file=world_hdr_file)
    
    # and make new fire.def by copying original
  new.fire.def<-paste(def.names$fire[1],
                      Rep,".def",sep="")
  cur.fire.def<-paste(def.names$fire[1],
                      ".def",sep="")
  
  system(paste("cp ",cur.fire.def,new.fire.def,sep=" "))
  # then adding a line defining the current fire rep for the fire sizes file

  write(paste(Rep," fire_size_name"),append=TRUE,file=new.fire.def)
  
  all.list[[i]]<-list(Rep=Rep,rhessys.script=rhessys.script,outPre=outPre,
                        basin.var=basin.var,grow.var=grow.var)  
     
}
# so now the default and header files are pre-populated
# call mclapply
library(parallel)
cur.results.set<-mclapply(all.list,FUN = runFireMC.fn,
                          mc.cores=n.mc)
# mc.cores specifies how many rhessys runs to start
# this will return a list of length mc.cores,
# each of which is the individual list returned by runFireMCBase.fn

# combine the list into single dataframes for each
# to aid in post-processing
all.fire.results<-cur.results.set[[1]]$fire.results
all.rhessys.results<-cur.results.set[[1]]$rhessys.results
all.fire.results$Rep<-iter.mc.reps[1]
all.rhessys.results$Rep<-iter.mc.reps[1]
for(k in 2:length(cur.results.set))
{
  tmp.fire<-cur.results.set[[k]]$fire.results
  tmp.fire$Rep<-iter.mc.reps[k]
  tmp.rhessys<-cur.results.set[[k]]$rhessys.results
  tmp.rhessys$Rep<-iter.mc.reps[k]
  all.fire.results<-rbind(all.fire.results,tmp.fire)
  all.rhessys.results<-rbind(all.rhessys.results,tmp.rhessys)
}
cur.results.set<-list(fire.results=all.fire.results,
                      rhessys.results=all.rhessys.results)
save(cur.results.set,file=paste("BCResultsPart",args[1],
                                ".RData",sep=""))

