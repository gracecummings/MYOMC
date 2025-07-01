#!/bin/bash
mv pileupinput.dat pileupinput.dat.$(date +"%Y-%m-%d-%H-%M-%S")
#dasgoclient -query="file dataset=/Neutrino_E-10_gun/RunIISummer20ULPrePremix-UL18_106X_upgrade2018_realistic_v11_L1v1-v2/PREMIX" > pileupinput.dat
dasgoclient -query="file dataset=/Neutrino_E-10_gun/RunIISummer20ULPrePremix-UL18_106X_upgrade2018_realistic_v11_L1v1-v2/PREMIX site=T1_US_FNAL_Disk" > pileupinput.dat
