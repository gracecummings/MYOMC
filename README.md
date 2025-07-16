# Make your own MC

This repository proves scripts to run private MC generation. It consists of the exact same (almost) cmsDriver.py commands used in central production (...painstaking copied by hand from MCM by David Yu, the main author of this code base, and Grace Cummings, who is adding the direct from pythia campaigns.

Setup instructions (note: `git cms-addpkg` has to work):
```
git clone git@github.com:gracecummings/MYOMC.git
cd MYOMC
```
# Make your own R-Hadron MC for the HSCP analysis

We want to use this code base to make private R-hadron simulation for the HSCP analysis using updated simualtion. To do this, CMSSW that was not used for the main UL production needs to be used for the simulatio step, and these directions do that.

This is checked and working on the cmslpc cluster.


## 2018 Private R-Hadron MC - local test w/ interactive running

First, we have to make sure we have a valid grid proxy, everything is linked correctly, and enter a container.

```
voms-proxy-init --valid 192:00 -voms cms
source env.sh 
cmssw-el7 -p --bind `readlink $HOME` --bind /uscms_data/ --bind /cvmfs
```

Enter the `test` directory:

```
cd $MYOMC/test
source runrhadtest.sh localrhad
```

See the test script for the syntax. This script will also run local tests of generation campaigns that need an LHE generated first (i.e., using MadGraph) using a fragment that generates Z'--> qq samples.

This script runs a local test instance of the generator. It builds all of the releases you need inside the test directory, and is hardcoded to take an input pileup distribuion.

### Notes on pileup distributions

The pileup files taken from the database have a high chance of being on tape, so make sure to remake the `pileupinput.dat` file. This `.dat` file is a list of the all of the premixed pileuip digi root files that can be overlayed. This new list can be created  with a "site=T1_US_FNAL_Disk" (or another disk location) flag added to the `dasgoclient` call. The new `pileupinput.dat` file needs to live in the campaign folder. To see what you have, do, for example

```
cd $MYOMC/campaigns/RunIISummer20UL18wmLHE
ls
```

You can remake the file when you source `getpileupfiles.sh.` This script wraps a `dasgoclient` call.


When you run

```
source getpileup.sh
```

make sure you are in a CMSSW release w/ `cmsenv` called.

## Running batch job

Running a batch job takes a bit more work -- this code base uses HTCondor, and transfers the CMSSW environment(s) via a tarball. The environment *must be built within the cmssw-el7 container*. Once it is built, *you do not submit jobs from the container*. In fact, you cannot!

### Building environment needed for R-hadron batch jobs (only needs to be done once)

Next, we want to setup an environment that lets us generate samples. *This must be done within the container!* In the orignal repo, different CMSSW releases were used for different steps - this fork is no different! The setup script sourced builds the releases that are necessary to run the code.

If you are not already in a el7 container, enter

```
cmssw-el7 -p --bind `readlink $HOME` --bind /uscms_data/ --bind /cvmfs
```

Next, let's enter the campaign needed for R-Hadron generation. These steps are the same of any of the campaigns in the repo, *but this is an example to Run II 2018 UL R-Hadron generation*.

```
cd $MYOMC/campaigns/RunIISummer20UL18GEN
source setup_env.sh
```

This will take a few minutes. All of the releases are built in the `env` subdirectory of the campaign.

### Submitting the batch jobs

To submit batch jobs, *make sure you are not in a container*, and enter the base directory.

```
cd $MYOMC
```

If you do not have a valid grid proxy,

```
voms-proxy-init --valid 192:00 -voms cms
```

Before submitting any jobs,

```
source env.sh
```

To see all of the options available in the batch job, run

```
python crun.py -h
```

The fragements that are availble for r-hadron submission are

```
test/EXO-RunIISummer20UL18GENSIM_gluinoOnlyNeutral_fragment.py
test/EXO-RunIISummer20UL18GENSIM_gluino_fragment.py
```

The fragments are taken from the McM.

An example job submission command producing AOD files ONLY from R-hadron simulation in a *premade* lpceos directory:

```
python crun.py gluino_1600_prod test/EXO-RunIISummer20UL18GENSIM_gluino_fragment.py RunIISummer20UL18GEN --env --pileup_file --nevents_job 300 --mass_rhad 1600 --njobs 50 --keepRECO --outEOS /store/group/lpchscp/gcumming/signalv3_prod_2025-07-15/gluino_1600/ --seed_offset 6
```
