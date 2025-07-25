FLAVOR = 'gluino'
COM_ENERGY = 13000. # GeV
MASS_POINT = 1800   # GeV
PROCESS_FILE = 'SimG4Core/CustomPhysics/data/RhadronProcessList_onlyneutral.txt'
PARTICLE_FILE = 'Configuration/Generator/data/particles_%s_%d_GeV.txt'  % (FLAVOR, MASS_POINT)
SLHA_FILE ='Configuration/Generator/data/HSCP_%s_%d_SLHA.spc' % (FLAVOR, MASS_POINT)
PDT_FILE = 'Configuration/Generator/data/hscppythiapdt%s%d.tbl'  % (FLAVOR, MASS_POINT)
USE_REGGE = False

import FWCore.ParameterSet.Config as cms
from Configuration.Generator.Pythia8CommonSettings_cfi import *
from Configuration.Generator.MCTunes2017.PythiaCP5Settings_cfi import *

generator = cms.EDFilter("Pythia8ConcurrentGeneratorFilter",
    pythiaPylistVerbosity = cms.untracked.int32(0),
    
    pythiaHepMCVerbosity = cms.untracked.bool(False),
    comEnergy = cms.double(COM_ENERGY),
    crossSection = cms.untracked.double(-1),
    maxEventsToPrint = cms.untracked.int32(0),
    SLHAFileForPythia8 = cms.string('%s' % SLHA_FILE), 
    PythiaParameters = cms.PSet(
        pythia8CommonSettingsBlock,
        pythia8CP5SettingsBlock,
        processParameters = cms.vstring(
            'SUSY:all = off',
            'SUSY:gg2gluinogluino = on',
            'SUSY:qqbar2gluinogluino = on',
            'RHadrons:allow  = on',
            'RHadrons:allowDecay = off',
            'RHadrons:setMasses = on',
            'RHadrons:probGluinoball = 0.10000001',
            ),
        parameterSets = cms.vstring(
            'pythia8CommonSettings',
            'pythia8CP5Settings',
            'processParameters'
            )    
        )
)

generator.hscpFlavor = cms.untracked.string(FLAVOR)
generator.massPoint = cms.untracked.int32(MASS_POINT)
generator.particleFile = cms.untracked.string(PARTICLE_FILE)
generator.slhaFile = cms.untracked.string(SLHA_FILE)
generator.processFile = cms.untracked.string(PROCESS_FILE)
generator.pdtFile = cms.FileInPath(PDT_FILE)
generator.useregge = cms.bool(USE_REGGE)

dirhadrongenfilter = cms.EDFilter("MCParticlePairFilter",
    Status = cms.untracked.vint32(1, 1),
    MinPt = cms.untracked.vdouble(0., 0.),
    MinP = cms.untracked.vdouble(0., 0.),
    MaxEta = cms.untracked.vdouble(100., 100.),
    MinEta = cms.untracked.vdouble(-100, -100),
    ParticleCharge = cms.untracked.int32(0),
    ParticleID1 = cms.untracked.vint32(1000993,1009213,1009313,1009323,1009113,1009223,1009333,1091114,1092114,1092214,1092224,1093114,1093214,1093224,1093314,1093324,1093334),
    ParticleID2 = cms.untracked.vint32(1000993,1009213,1009313,1009323,1009113,1009223,1009333,1091114,1092114,1092214,1092224,1093114,1093214,1093224,1093314,1093324,1093334)
)

ProductionFilterSequence = cms.Sequence(generator*dirhadrongenfilter)
