#!/bin/bash
#crun.py test_Bu2PiJpsi2PiMuMu $MYOMCPATH/test/fragment.py RunIIFall18GS \
#    --gfalcp "gsiftp://brux11.hep.brown.edu/mnt/hadoop/store/user/dryu/BParkingMC/test/" \
#    --keepMini \
#    --nevents_job 5 \
#    --njobs 5 \
#    --env

QUEUE=${1}
if [ -z ${QUEUE} ]; then
    QUEUE=local
fi

#CAMPAIGNS=( "RunIISummer20UL16wmLHE" "RunIISummer20UL16APVwmLHE" "RunIISummer20UL17wmLHE" "RunIISummer20UL18wmLHE" )
CAMPAIGNS=( "RunIISummer20UL18wmLHE" )

if [ "$QUEUE" == "condor" ]; then
    for CAMPAIGN in "${CAMPAIGNS[@]}"; do
        crun.py test_zpqq $MYOMCPATH/test/fragment_zpqq.py ${CAMPAIGN} \
            --outEOS "/store/user/$USER/MYOMC/test/${CAMPAIGN}/$(date +"%Y-%m-%d-%H-%M-%S")/" \
            --keepMINI \
            --keepNANO \
            --nevents_job 16 \
            --njobs 4 \
            --env \
            --overwrite
    done
elif [ "$QUEUE" == "condor_eos" ]; then
    crun.py test_zpqq $MYOMCPATH/test/fragment_zpqq.py RunIISummer20UL17wmLHE \
        --keepMINI \
        --keepNANO \
        --nevents_job 8 \
        --njobs 4 \
        --env
elif [ "$QUEUE" == "local" ]; then
    STARTDIR=$PWD
    mkdir testrun_june
    cd testrun
    source "$STARTDIR/../campaigns/RunIISummer20UL18wmLHE/run.sh" test "$STARTDIR/fragment_zpqq.py" 3 1 1 "$STARTDIR/../campaigns/RunIISummer20UL18wmLHE/pileupinput.dat"
    # Args are: name fragment_path nevents random_seed nthreads pileup_filelist
    cd $STARTDIR
elif [ "$QUEUE" == "localrhad" ]; then
    echo Running 2018 Gluino UL AOD production test locally
    echo using fragment Configuration/GenProduction/python/EXO-RunIISummer20UL18GENSIM-00010-fragment.py
    STARTDIR=$PWD
    mkdir testrun_rhad
    cd testrun_rhad
    source "$STARTDIR/../campaigns/RunIISummer20UL18GEN/run.sh" test_rhad "$STARTDIR/EXO-RunIISummer20UL18GENSIM-00010-fragment.py" 2 3 1 "$STARTDIR/../campaigns/RunIISummer20UL18GEN/pileupinput.dat" "1600"
    # Args are: name fragment_path nevents random_seed nthreads pileup_filelist gluino_mass(optional, default will be used otherwise)
    cd $STARTDIR
fi
