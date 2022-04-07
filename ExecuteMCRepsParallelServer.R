# take as arguments the first and last in sequence
# for the MC reps
args=commandArgs(trailingOnly = TRUE)
if(length(args)<2)
{
  stop("ERROR: Needs two arguments",call.=FALSE)
}
#
# source the function that runs RHESSys
source("~/GITRepos/ParallelRhessysFireRProjRepo/runFireMC_FN.R")
# source the output filters from RHESSysIOInR (until figure out how to install package)
source("~/GITRepos/RHESSysIOinR/R/build_output_filter.R")
source("~/GITRepos/RHESSysIOinR/R/IOin_output_filters.R")
source("~/GITRepos/RHESSysIOinR/R/modify_output_filter.R")
source("~/GITRepos/RHESSysIOinR/R/read_output_filter.R")
source("~/GITRepos/RHESSysIOinR/R/write_output_filter.R")
source("~/GITRepos/RHESSysIOinR/R/utils.R")
source("~/GITRepos/RHESSysIOinR/R/write_output_filter.R")

# source("runFireMC_FN.R")
# # source the output filters from RHESSysIOInR (until figure out how to install package)
# source("~/GitRepos/RHESSysIOinR/R/build_output_filter.R")
# source("~/GitRepos/RHESSysIOinR/R/IOin_output_filters.R")
# source("~/GitRepos/RHESSysIOinR/R/modify_output_filter.R")
# source("~/GitRepos/RHESSysIOinR/R/read_output_filter.R")
# source("~/GitRepos/RHESSysIOinR/R/write_output_filter.R")
# source("~/GitRepos/RHESSysIOinR/R/utils.R")
# source("~/GitRepos/RHESSysIOinR/R/write_output_filter.R")


# 
# load in the submitPBSScripts.R workspace
# to have consistent settings
load("CurrentBatchSettings.RData")
########
# first setup the output filters



# Next set up the default and header files
# for the current set of MC reps. These should
# be customized for individual applications
#outPre="BCbasin30mFire_su" # prefix for rhessys output files
# Below are the required components of the RHESSys commandline
# note that the world_hdr_file is just the prefix
# that will be updated by the function. Use the same prefix *.hdr,
# where the prefix is * before .hdr
#########Locate RHESSys
# Cheyenne:
cur.rhessys.ver<-"~/GITRepos/RHESSys/rhessys/rhessys7.4"
# uwtresearch1:
#cur.rhessys.ver<-"~/GITRepos/RHESSysSalience/RHESSys/rhessys/rhessys7.3"
rhessys.script=list(rhessys_version=cur.rhessys.ver,
                    tec_file="../tecfiles/tec.su",
                    world_file="../worldfiles/BCbasin30mSUfireSal.world",
                    world_hdr_file="../worldfiles/BCbasin30mSalFireNoEffects",
                    flow_file="../flowtables/BCbasin30m.flow",
                    start_date="1941 10 1 1",
                    end_date="2000 10 1 1",
                    prefix=outPre,
                    command_options=c("-s 3.107846 291.838599 -sv 3.107846 291.838599 -svalt 1.326919 0.797249 -gw 0.188211 0.299011 -g -vmort_off -firespread 30"))# ../auxdata/patchGrid.txt ../auxdata/DemGrid.txt"))
# this vector defines the number of default files
# for basin, hillslope,zone,patch,landuse,canopy_strata,
# fire, and base_stations, respectively
n.defs=c(basin=1,hillslope=1,zone=1,patch=2,
         landuse=1,canopy_strata=4,fire=1,fire.pre=1,base_stations=1)
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
               fire="../defs/fireBCNoEffects",
               fire.pre="../auxdata/BC",
               base_stations="../clim/Grove_lowprov_clim.base")
# how many MC reps per node? Here we assume 4 replicates,
# each of which will take 9 omp threads for a total of
# 36 cpus per job
n.mc<-iter.mc
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
  hdr.input<-NA # make a custom header file for this iter
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
  
  # Make output filters for this rep--basin-level
  outfilter = build_output_filter(
    timestep = "daily",
    output_format = "csv",
    output_path = paste("\"",outPath,"\"",sep=""),
    output_filename=paste("\"",outPre,Rep,"\"",sep=""),
#    output_filename = gsub("\\.","",paste0(name,"_basin")),
    spatial_level = "basin",
    spatial_ID = 1, # replace next line with basin.var
    variables = basin.var
  )
  # if (opts$type[i] == "msr") {
  #   outfilter$filter$output$filename = "p301_h2_basin_msr"
  # }
  
  # outfilter2 = build_output_filter(
  #   timestep = "yearly",
  #   output_format = "csv",
  #   output_path = "../output/",
  #   output_filename = gsub("\\.","",paste0(name,"_stratum")),
  #   spatial_level = "stratum",
  #   spatial_ID = "2:2",
  #   #variables = c("epv.height", "cs.totalc", "epv.proj_lai", 'transpiration_unsat_zone', "transpiration_sat_zone", "rootzone.S")
  #   variables = c("epv.height", "cs.totalc", "epv.proj_lai", "transpiration_unsat_zone", "transpiration_sat_zone", "cs.live_stemc", "cs.dead_stemc",
  #                 "cdf.psn_to_cpool", "cdf.total_mr", "cdf.total_gr", "cs.cpool")
  # )
  file_name<-paste(filterPath,"/",filterName,Rep,".yml",sep="")
  output_filter = IOin_output_filters(outfilter)
  
  yaml_out = yaml::as.yaml(x = output_filter)
  yaml_out = gsub("\\.0", "", yaml_out)
  yaml_out = gsub("'", "", yaml_out)
  
  file = file(file_name, "w")
  cat(yaml_out, file = file, sep = "")
  close(file)
  
  
  
  
  all.list[[i]]<-list(Rep=Rep,rhessys.script=rhessys.script,filter.name=file_name,outPre=outPre)#,
                        #basin.var=basin.var,grow.var=grow.var)  
     
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
all.results<-list(fire.results=all.fire.results,
                      rhessys.results=all.rhessys.results)
# workspace.pre is from the SubmitPBSScriptsWorkspace
save(all.results,file=paste(workspace.pre,args[1],
                                ".RData",sep=""))

