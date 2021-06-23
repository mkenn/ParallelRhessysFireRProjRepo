###########
# function to call rhessys/wmfire with unique output prefix
# for use in parallelized R environment
# includes changing FireSizes name by replicate run in current
# directory with a change to the fire default file
############
# first the function to run 1 MC replicate (Rep)
# takes a single list as an argument
# in.list, which has:
# Rep, outPre, rhessys.script, grow.var, basin.var
runFireMC.fn<-function(in.list) # rep is the integer indexing the current replicate
{
  #  rhessys.script=in.list$rhessys.script
  set.seed(seed=NULL) # makes a unique random number
  
  cur.fire.sizes<-paste("FireSizes",in.list$Rep,".txt",sep="") # unique FireSizes file
  if(file.exists(cur.fire.sizes))
    system(paste("rm",cur.fire.sizes,sep=" "))
  # remove the existing fire sizes file so it is not appended to
  
  # in pre-processing create fire default files
  # and headers for each desired MC replicate
  
  # Header file updated with the Rep appended Fire.def file 
  world_hdr_file <- paste(in.list$rhessys.script$world_hdr_file,
                          in.list$Rep,".hdr",sep="")
  # make a new rhessys command, relies on global variable rhessys.script being defined  
  tmp <- sprintf("%s -w %s -whdr %s -t %s -r %s -st %s -ed %s -of %s %s", 
                 in.list$rhessys.script$rhessys_version, 
                 in.list$rhessys.script$world_file, 
                 world_hdr_file, 
                 in.list$rhessys.script$tec_file, 
                 in.list$rhessys.script$flow_file, 
                 in.list$rhessys.script$start_date, 
                 in.list$rhessys.script$end_date, 
                 in.list$filter.name, 
                 in.list$rhessys.script$command_options)
  
#  system("export LD_LIBRARY_PATH='/home/mkenn/GITRepos/RHESSysSalience/RHESSys/rhessys/lib/:/opt/netcdf/4.8.0/lib'")
# uwtresearch1
#  system(paste("export LD_LIBRARY_PATH='/home/mkenn/GITRepos/RHESSysSalience/RHESSys/rhessys/lib/:/opt/netcdf/4.8.0/lib'",tmp,sep="\n")) # modify this for your own output needs
#cheyenne
  system(paste("export LD_LIBRARY_PATH='/glade/u/home/mkennedy/RHESSysGit/RHESSys/rhessys/lib/'",tmp,sep="\n")) # modify this for your own output needs
 cur.out<-paste("../output/",in.list$outPre,in.list$Rep,sep="")
  results1.file<-paste(cur.out,"_basin.csv",sep="")
#  results2.file<-paste(cur.out,"_grow_basin.daily",sep="")
  
  # from rhessys file formats, column names for time variables  
#  date.out<-c("day","month","year")
  # readin the rhessys results files  
  results1.df<-read.csv(results1.file)
#  results2.df<-read.table(results2.file,header=TRUE)
  # create a column to record the current MC Rep
  cur.rep<-rep(in.list$Rep,nrow(results1.df))
  # make a new results data frame with only the variables of interest
  results.tmp<-cbind(cur.rep,results1.df)
  names(results.tmp)[1]<-"Rep"
  # readin the FireSizes file and make its MC rep column
  cur.fires<-read.table(cur.fire.sizes)
  cur2.rep<-rep(in.list$Rep,nrow(cur.fires))
  # name the columns and fill in the rep column
  names(cur.fires)<-c("FirePix","Year","Month","wind1",
                      "wind2","nign")
  cur.fires$Rep<-cur2.rep
  # return separate the fire results and the rhessys results  
  return(list(fire.results=cur.fires,rhessys.results=results.tmp))
}

