#!/bin/bash
echo "if this is not run in sl7 container, it will not work! torch it and start over"
if [ -d env ]; then
	rm -rf env
fi

mkdir env
cd env
export SCRAM_ARCH=slc7_amd64_gcc700
source /cvmfs/cms.cern.ch/cmsset_default.sh

scram project -n "CMSSW_10_6_47" CMSSW_10_6_47
cd CMSSW_10_6_47/src
eval `scram runtime -sh`
scram b
cd ../..

scram project -n "CMSSW_10_6_17_patch1" CMSSW_10_6_17_patch1
cd  CMSSW_10_6_17_patch1/src
eval `scram runtime -sh`
scram b
cd ../..

scram project -n "CMSSW_10_2_16_UL" CMSSW_10_2_16_UL
cd  CMSSW_10_2_16_UL/src
eval `scram runtime -sh`
scram b
cd ../..

echo taring environments
tar -czf env.tar.gz ./CMSSW*
mv env.tar.gz ..
cd ..

eval `scram unsetenv -sh`



