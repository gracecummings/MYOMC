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

#GEC Changing to the bug fix release
if [ -r CMSSW_10_6_47/src ] ; then 
    echo release CMSSW_10_6_47 already exists
    cd CMSSW_10_6_47/src
    eval `scram runtime -sh`
else
    scram project -n "CMSSW_10_6_47" CMSSW_10_6_47
    cd CMSSW_10_6_47/src
    eval `scram runtime -sh`
fi


#original cms release
#if [ -r CMSSW_10_6_40/src ] ; then 
#    echo release CMSSW_10_6_40 already exists
#    cd CMSSW_10_6_40/src
#    eval `scram runtime -sh`
#else
#    scram project -n "CMSSW_10_6_40" CMSSW_10_6_40
#    cd CMSSW_10_6_40/src
#    eval `scram runtime -sh`
#fi

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

cmsDriver.py Configuration/GenProduction/python/fragment.py \
    --python_filename "RunIISummer20UL18wmLHE_${NAME}_cfg.py" \
    --eventcontent RAWSIM,LHE \
    --customise Configuration/DataProcessing/Utils.addMonitoring \
    --datatier GEN,LHE \
    --fileout "file:RunIISummer20UL18wmLHE_$NAME_$JOBINDEX.root" \
    --conditions 106X_upgrade2018_realistic_v4 \
    --beamspot Realistic25ns13TeVEarly2018Collision \
    --step LHE,GEN \
    --geometry DB:Extended \
    --era Run2_2018 \
    --no_exec \
    --nThreads $(( $MAX_NTHREADS < 8 ? $MAX_NTHREADS : 8 )) \
    --customise_commands "process.source.numberEventsInLuminosityBlock=cms.untracked.uint32(1000)\\nprocess.RandomNumberGeneratorService.externalLHEProducer.initialSeed=${RSEED}" \
    --mc \
    -n $NEVENTS 
cmsRun "RunIISummer20UL18wmLHE_${NAME}_cfg.py"
if [ ! -f "RunIISummer20UL18wmLHE_$NAME_$JOBINDEX.root" ]; then
    echo "RunIISummer20UL18wmLHE_$NAME_$JOBINDEX.root not found. Exiting."
    return 1
fi


# SIM
export SCRAM_ARCH=slc7_amd64_gcc700
source /cvmfs/cms.cern.ch/cmsset_default.sh

#GEC Changing to the bug fix release
if [ -r CMSSW_10_6_47/src ] ; then 
    echo release CMSSW_10_6_47 already exists
    cd CMSSW_10_6_47/src
    eval `scram runtime -sh`
else
    scram project -n "CMSSW_10_6_47" CMSSW_10_6_47
    cd CMSSW_10_6_47/src
    eval `scram runtime -sh`
fi

#orginial release
#if [ -r CMSSW_10_6_17_patch1/src ] ; then
#    echo release CMSSW_10_6_17_patch1 already exists
#    cd CMSSW_10_6_17_patch1/src
#    eval `scram runtime -sh`
#else
#    scram project -n "CMSSW_10_6_17_patch1" CMSSW_10_6_17_patch1
#    cd CMSSW_10_6_17_patch1/src
#    eval `scram runtime -sh`
#fi

cd $CMSSW_BASE/src
scram b
cd $TOPDIR

cmsDriver.py  \
    --python_filename "RunIISummer20UL18SIM_${NAME}_cfg.py" \
    --eventcontent RAWSIM \
    --customise Configuration/DataProcessing/Utils.addMonitoring \
    --datatier GEN-SIM \
    --fileout "file:RunIISummer20UL18SIM_$NAME_$JOBINDEX.root" \
    --conditions 106X_upgrade2018_realistic_v11_L1v1 \
    --beamspot Realistic25ns13TeVEarly2018Collision \
    --step SIM \
    --geometry DB:Extended \
    --filein "file:RunIISummer20UL18wmLHE_$NAME_$JOBINDEX.root" \
    --era Run2_2018 \
    --runUnscheduled \
    --no_exec \
    --mc \
    --nThreads $(( $MAX_NTHREADS < 8 ? $MAX_NTHREADS : 8 )) \
    -n $NEVENTS
cmsRun "RunIISummer20UL18SIM_${NAME}_cfg.py"
if [ ! -f "RunIISummer20UL18SIM_$NAME_$JOBINDEX.root" ]; then
    echo "RunIISummer20UL18SIM_$NAME_$JOBINDEX.root not found. Exiting."
    return 1
fi


# DIGIPremix --> done in the same release as the simulation in the original fork. now will get new bug fix release
cd $TOPDIR
cmsDriver.py  \
    --python_filename "RunIISummer20UL18DIGIPremix_${NAME}_cfg.py" \
    --eventcontent PREMIXRAW \
    --customise Configuration/DataProcessing/Utils.addMonitoring \
    --datatier GEN-SIM-DIGI \
    --filein "file:RunIISummer20UL18SIM_$NAME_$JOBINDEX.root" \
    --fileout "file:RunIISummer20UL18DIGIPremix_$NAME_$JOBINDEX.root" \
    --pileup_input "$PILEUP_FILELIST" \
    --conditions 106X_upgrade2018_realistic_v11_L1v1 \
    --step DIGI,DATAMIX,L1,DIGI2RAW \
    --procModifiers premix_stage2 \
    --geometry DB:Extended \
    --datamix PreMix \
    --era Run2_2018 \
    --runUnscheduled \
    --no_exec \
    --mc \
    --nThreads $(( $MAX_NTHREADS < 8 ? $MAX_NTHREADS : 8 )) \
    -n $NEVENTS
cmsRun "RunIISummer20UL18DIGIPremix_${NAME}_cfg.py"
if [ ! -f "RunIISummer20UL18DIGIPremix_$NAME_$JOBINDEX.root" ]; then
    echo "RunIISummer20UL18DIGIPremix_$NAME_$JOBINDEX.root not found. Exiting."
    return 1
fi


# HLT --> leaving this step in the HLT release from the original fork
export SCRAM_ARCH=slc7_amd64_gcc630
source /cvmfs/cms.cern.ch/cmsset_default.sh
if [ -r CMSSW_10_2_16_UL/src ] ; then
    echo release CMSSW_10_2_16_UL already exists
    cd CMSSW_10_2_16_UL/src
    eval `scram runtime -sh`
else
    scram project -n "CMSSW_10_2_16_UL" CMSSW_10_2_16_UL
    cd CMSSW_10_2_16_UL/src
    eval `scram runtime -sh`
fi
cd $CMSSW_BASE/src
scram b
cd $TOPDIR

cmsDriver.py  \
    --python_filename "RunIISummer20UL18HLT_${NAME}_cfg.py" \
    --eventcontent RAWSIM \
    --customise Configuration/DataProcessing/Utils.addMonitoring \
    --datatier GEN-SIM-RAW \
    --filein "file:RunIISummer20UL18DIGIPremix_$NAME_$JOBINDEX.root" \
    --fileout "file:RunIISummer20UL18HLT_$NAME_$JOBINDEX.root" \
    --conditions 102X_upgrade2018_realistic_v15 \
    --customise_commands 'process.source.bypassVersionCheck = cms.untracked.bool(True)' \
    --step HLT:2018v32 \
    --geometry DB:Extended \
    --era Run2_2018 \
    --no_exec \
    --mc \
    -n $NEVENTS
cmsRun "RunIISummer20UL18HLT_${NAME}_cfg.py"
if [ ! -f "RunIISummer20UL18HLT_$NAME_$JOBINDEX.root" ]; then
    echo "RunIISummer20UL18HLT_$NAME_$JOBINDEX.root not found. Exiting."
    return 1
fi


# RECO --> changing because it was also coorindated

#need to keep this in case we need it to build old version
#if [ -r CMSSW_10_6_17_patch1/src ] ; then
#    echo release CMSSW_10_6_17_patch1 already exists
#    cd CMSSW_10_6_17_patch1/src
#    eval `scram runtime -sh`
#else
#    scram project -n "CMSSW_10_6_17_patch1" CMSSW_10_6_17_patch1
#    cd CMSSW_10_6_17_patch1/src
#    eval `scram runtime -sh`
#fi

export SCRAM_ARCH=slc7_amd64_gcc700
cd CMSSW_10_6_47/src
eval `scram runtime -sh`
cd $CMSSW_BASE/src
scram b
cd $TOPDIR

cmsDriver.py  \
    --python_filename "RunIISummer20UL18RECO_${NAME}_cfg.py" \
    --eventcontent AODSIM \
    --customise Configuration/DataProcessing/Utils.addMonitoring \
    --datatier AODSIM \
    --filein "file:RunIISummer20UL18HLT_$NAME_$JOBINDEX.root" \
    --fileout "file:RunIISummer20UL18RECO_$NAME_$JOBINDEX.root" \
    --conditions 106X_upgrade2018_realistic_v11_L1v1 \
    --step RAW2DIGI,L1Reco,RECO,RECOSIM \
    --geometry DB:Extended \
    --era Run2_2018 \
    --runUnscheduled \
    --no_exec \
    --nThreads $(( $MAX_NTHREADS < 8 ? $MAX_NTHREADS : 8 )) \
    --mc \
    -n $NEVENTS 
cmsRun "RunIISummer20UL18RECO_${NAME}_cfg.py"
if [ ! -f "RunIISummer20UL18RECO_$NAME_$JOBINDEX.root" ]; then
    echo "RunIISummer20UL18RECO_$NAME_$JOBINDEX.root not found. Exiting."
    return 1
fi


# MiniAOD --> leaving same as the original fork
export SCRAM_ARCH=slc7_amd64_gcc700
source /cvmfs/cms.cern.ch/cmsset_default.sh
if [ -r CMSSW_10_6_20/src ] ; then
    echo release CMSSW_10_6_20 already exists
    cd CMSSW_10_6_20/src
    eval `scram runtime -sh`
else
    scram project -n "CMSSW_10_6_20" CMSSW_10_6_20
    cd CMSSW_10_6_20/src
    eval `scram runtime -sh`
fi
cd $CMSSW_BASE/src
scram b
cd $TOPDIR

cmsDriver.py  \
    --python_filename "RunIISummer20UL18MINIAODSIM_${NAME}_cfg.py" \
    --eventcontent MINIAODSIM \
    --customise Configuration/DataProcessing/Utils.addMonitoring \
    --datatier MINIAODSIM \
    --filein "file:RunIISummer20UL18RECO_$NAME_$JOBINDEX.root" \
    --fileout "file:RunIISummer20UL18MINIAODSIM_$NAME_$JOBINDEX.root" \
    --conditions 106X_upgrade2018_realistic_v16_L1v1 \
    --step PAT \
    --procModifiers run2_miniAOD_UL \
    --geometry DB:Extended \
    --era Run2_2018 \
    --runUnscheduled \
    --no_exec \
    --nThreads $(( $MAX_NTHREADS < 8 ? $MAX_NTHREADS : 8 )) \
    --mc \
    -n $NEVENTS
cmsRun "RunIISummer20UL18MINIAODSIM_${NAME}_cfg.py"
if [ ! -f "RunIISummer20UL18MINIAODSIM_$NAME_$JOBINDEX.root" ]; then
    echo "RunIISummer20UL18MINIAODSIM_$NAME_$JOBINDEX.root not found. Exiting."
    return 1
fi


# NanoAOD --> leaving same as the original fork
export SCRAM_ARCH=slc7_amd64_gcc700
source /cvmfs/cms.cern.ch/cmsset_default.sh
if [ -r CMSSW_10_6_32_patch1/src ] ; then
    echo release CMSSW_10_6_32_patch1 already exists
    cd CMSSW_10_6_32_patch1/src
    eval `scram runtime -sh`
else
    scram project -n "CMSSW_10_6_32_patch1" CMSSW_10_6_26
    cd CMSSW_10_6_32_patch1/src
    eval `scram runtime -sh`
fi
cd $CMSSW_BASE/src
scram b
cd $TOPDIR

cmsDriver.py  \
    --python_filename "RunIISummer20UL18NANOAODSIM_${NAME}_cfg.py" \
    --filein "file:RunIISummer20UL18MINIAODSIM_$NAME_$JOBINDEX.root" \
    --fileout "file:RunIISummer20UL18NANOAODSIM_$NAME_$JOBINDEX.root" \
    --eventcontent NANOAODSIM \
    --customise Configuration/DataProcessing/Utils.addMonitoring \
    --customise_commands="process.add_(cms.Service('InitRootHandlers', EnableIMT = cms.untracked.bool(False)))" \
    --datatier NANOAODSIM \
    --conditions 106X_upgrade2018_realistic_v16_L1v1 \
    --step NANO \
    --era Run2_2018,run2_nanoAOD_106Xv2 \
    --no_exec \
    --mc \
    --nThreads $(( $MAX_NTHREADS < 8 ? $MAX_NTHREADS : 8 )) \ \
    -n $NEVENTS
cmsRun "RunIISummer20UL18NANOAODSIM_${NAME}_cfg.py"
if [ ! -f "RunIISummer20UL18NANOAODSIM_$NAME_$JOBINDEX.root" ]; then
    echo "RunIISummer20UL18NANOAODSIM_$NAME_$JOBINDEX.root not found. Exiting."
    return 1
fi
