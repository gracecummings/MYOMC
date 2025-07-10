# Run private production using RunIIFall18GS settings.
# Local example:
# source run.sh MyMCName /path/to/fragment.py 1000 1 1 filelist:/path/to/pileup/list.txt
# 
# Batch example:
# python crun.py MyMCName /path/to/fragment.py --outEOS /store/user/myname/somefolder --keepMini --nevents_job 10000 --njobs 100 --env
# See crun.py for full options, especially regarding transfer of outputs.
# Make sure your gridpack is somewhere readable, e.g. EOS or CVMFS.
# Make sure to run setup_env.sh first to create a CMSSW tarball (have to patch the DR step to avoid taking forever to uniqify the list of 300K pileup files)
echo $@

if [ -z "$1" ]; then
    echo "Argument 1 (name of job) is mandatory."
    return 1
fi
NAME=$1

if [ -z $2 ]; then
    echo "Argument 2 (fragment path) is mandatory."
    return 1
fi
FRAGMENT=$2
echo "Input arg 2 = $FRAGMENT"
FRAGMENT=$(readlink -e $FRAGMENT)
echo "After readlink fragment = $FRAGMENT"

if [ -z "$3" ]; then
    NEVENTS=100
else
    NEVENTS=$3
fi

if [ -z "$4" ]; then
    JOBINDEX=1
else
    JOBINDEX=$4
fi

if [ -z "$5" ]; then
    MAX_NTHREADS=8
else
    MAX_NTHREADS=$5
fi
RSEED=$((JOBINDEX * MAX_NTHREADS * 4 + 1001)) # Space out seeds; Madgraph concurrent mode adds idx(thread) to random seed. The extra *4 is a paranoia factor.

if [ -z "$6" ]; then
    PILEUP_FILELIST="dbs:/Neutrino_E-10_gun/RunIISummer20ULPrePremix-UL18_106X_upgrade2018_realistic_v11_L1v1-v2/PREMIX" 
else
    PILEUP_FILELIST="filelist:$6"
fi

echo "Fragment=$FRAGMENT"
echo "Job name=$NAME"
echo "NEvents=$NEVENTS"
echo "Random seed=$RSEED"
echo "Pileup filelist=$PILEUP_FILELIST"

TOPDIR=$PWD

# wmLHE
export SCRAM_ARCH=slc7_amd64_gcc700
source /cvmfs/cms.cern.ch/cmsset_default.sh

#rhadron v3 bug fix release
if [ -r CMSSW_10_6_47/src ] ; then 
    echo release CMSSW_10_6_47 already exists
    cd CMSSW_10_6_47/src
    eval `scram runtime -sh`
else
    scram project -n "CMSSW_10_6_47" CMSSW_10_6_47
    cd CMSSW_10_6_47/src
    eval `scram runtime -sh`
fi

mkdir -pv $CMSSW_BASE/src/Configuration/GenProduction/python
cp $FRAGMENT $CMSSW_BASE/src/Configuration/GenProduction/python/fragment.py
if [ ! -f "$CMSSW_BASE/src/Configuration/GenProduction/python/fragment.py" ]; then
    echo "Fragment copy failed"
    exit 1
fi
cd $CMSSW_BASE/src
scram b
cd $TOPDIR

#cat $CMSSW_BASE/src/Configuration/GenProduction/python/fragment.py

##GENSIM step
echo Doing the GEN and SIM steps
#cmsDriver cmd taken from McM and generalized
#https://cms-pdmv-prod.web.cern.ch/mcm/public/restapi/requests/get_test/EXO-RunIISummer20UL18GENSIM-00010
cmsDriver.py Configuration/GenProduction/python/fragment.py \
	     --python_filename "RunIISummer20UL18GENSIM_${NAME}_cfg.py" \
	     --fileout "file:RunIISummer20UL18GENSIM_$NAME_$JOBINDEX.root" \
	     --eventcontent RAWSIM \
	     --customise SimG4Core/CustomPhysics/Exotica_HSCP_SIM_cfi.customise,Configuration/DataProcessing/Utils.addMonitoring \
	     --datatier GEN-SIM \
	     --conditions 106X_upgrade2018_realistic_v4 \
	     --beamspot Realistic25ns13TeVEarly2018Collision \
	     --customise_commands process.source.numberEventsInLuminosityBlock="cms.untracked.uint32(100)" \
	     --step GEN,SIM \
	     --geometry DB:Extended \
	     --era Run2_2018 \
	     --number $NEVENTS \
	     --number_out $NEVENTS \
	     --no_exec \
	     --mc
#cmsRun command using the .py config the previous part made
#this script you'd edit to change the generated masses
REPORT_NAME=RunIISummer20UL18GENSIM_report_$NAME_$JOBINDEX.xml
#cmsRun -e -j $REPORT_NAME "RunIISummer20UL18GENSIM_${NAME}_cfg.py"

#check that the GENSIM step worked
if [ ! -f "RunIISummer20UL18GENSIM_$NAME_$JOBINDEX.root" ]; then
    echo "RunIISummer20UL18GENSIM_$NAME_$JOBINDEX.root not found. Exiting."
    return 1
fi

##DIGIPremix step
export SCRAM_ARCH=slc7_amd64_gcc700
source /cvmfs/cms.cern.ch/cmsset_default.sh

cd $TOPDIR
echo Doing DIGI and PREMIX steps

#build CMSSW release used in official run 2 samples
#taken right from the test command in the McM
#https://cms-pdmv-prod.web.cern.ch/mcm/public/restapi/requests/get_test/EXO-RunIISummer20UL18DIGIPremix-00863
if [ -r CMSSW_10_6_17_patch1/src ] ; then
  echo release CMSSW_10_6_17_patch1 already exists
else
  scram p CMSSW CMSSW_10_6_17_patch1
fi
cd CMSSW_10_6_17_patch1/src
eval `scram runtime -sh`

#mv ../../Configuration .
#scram b
#cd ../..

cd $TOPDIR
#cmsDriver to build the .py config file
cmsDriver.py  \
    --eventcontent PREMIXRAW \
    --customise Configuration/DataProcessing/Utils.addMonitoring \
    --datatier GEN-SIM-DIGI \
    --conditions 106X_upgrade2018_realistic_v11_L1v1 \
    --step DIGI,DATAMIX,L1,DIGI2RAW \
    --procModifiers premix_stage2 \
    --geometry DB:Extended \
    --datamix PreMix \
    --era Run2_2018 \
    --python_filename "RunIISummer20UL18DIGIPremix_${NAME}_cfg.py" \
    --fileout "file:RunIISummer20UL18DIGIPremix_$NAME_$JOBINDEX.root" \
    --filein "file:RunIISummer20UL18GENSIM_$NAME_$JOBINDEX.root" \
    --number $NEVENTS \
    --number_out $NEVENTS \
    --pileup_input "$PILEUP_FILELIST" \
    --no_exec \
    --mc \
    --nThreads $(( $MAX_NTHREADS < 8 ? $MAX_NTHREADS : 8 )) \
    --runUnscheduled \
    
#cmsRun to actually execute
echo $PILEUP_FILELIST
cmsRun "RunIISummer20UL18DIGIPremix_${NAME}_cfg.py"
if [ ! -f "RunIISummer20UL18DIGIPremix_$NAME_$JOBINDEX.root" ]; then
    echo "RunIISummer20UL18DIGIPremix_$NAME_$JOBINDEX.root not found. Exiting."
    return 1
fi

#    --pileup_input "file:../../campaigns/RunIISummer20UL18wmLHE/pileupinput.dat" \
#--pileup_input "dbs:/Neutrino_E-10_gun/RunIISummer20ULPrePremix-UL18_106X_upgrade2018_realistic_v11_L1v1-v2/PREMIX"
