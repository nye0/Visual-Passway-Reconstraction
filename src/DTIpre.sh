#!/bin/bash
# concatenate all b-images into a mif file
AP="../data/DTI_AP/" #$1 #"../data/DTI_AP/"
PA_b0="../data/DTI_PA_b0/"
ResultRoot="../result/" #$2 #"../result/"
AP_raw=$ResultRoot/DTI_AP-raw.mif
AP_den=$ResultRoot/DTI_AP-den.mif
  AP_noise=$ResultRoot/DTI_AP-noise.mif
AP_den_unr=$ResultRoot/DTI_AP-den-unr.mif
  resUnring=$ResultRoot/DTI_AP-residualUnringed.mif
b0mean_AP=$ResultRoot/b0mean_AP.mif
b0mean_PA=$ResultRoot/b0mean_PA.mif
b0mean_pair=$ResultRoot/b0mean_pair.mif

a="
# DICOM2mif

mrconvert $AP $AP_raw


# Denoising

## from [manual](https://mrtrix.readthedocs.io/en/latest/dwi_preprocessing/denoising.html) 
## Patch size, 5x5x5 for data with <= 125 DWI volumes, 7x7x7 for data with <= 343 DWI volumes
dwidenoise $AP_raw $AP_den -noise $AP_noise


#Unringing

## Note that this method is designed to work on images acquired with full
## k-space coverage. Running this method on partial Fourier ('half-scan')
## data may lead to suboptimal and/or biased results, as noted in the
## original reference below.
mrdegibbs $AP_den $AP_den_unr -axes 0,1
## check unring result
mrcalc $AP_den $AP_den_unr -subtract $resUnring
mrview $AP_den_unr $resUnring &
"

#Motion and distortion correction

PreprocessedDTI_AP=$AP_den_unr
PreprocessedDTI_AP_preproc=${PreprocessedDTI_AP%%.mif}-prep.mif
dwiextract $PreprocessedDTI_AP - -bzero | mrmath - mean $b0mean_AP -axis 3
mrconvert $PA_b0 - | mrmath - mean $b0mean_PA -axis 3
mrcat $b0mean_AP $b0mean_PA -axis 3 $b0mean_pair
mrview $b0mean_AP -overlay.load $b0mean_PA &
dwipreproc $PreprocessedDTI_AP $PreprocessedDTI_AP_preproc \
	-pe_dir AP -rpe_pair \
	-se_epi $b0mean_pair \
	-eddy_option " --slm=linear"


#Bias field correction
DTI_unbiased=${PreprocessedDTI_AP_preproc%%.mif}-unbiased.mif
  bias=${PreprocessedDTI_AP_preproc%%.mif}-bias.mif
echo dwibiascorrect -ants $PreprocessedDTI_AP_preproc $DTI_unbiased \
	-bias $bias
dwibiascorrect -fsl $PreprocessedDTI_AP_preproc $DTI_unbiased \
        -bias $bias
