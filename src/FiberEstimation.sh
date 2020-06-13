#!/bin/bash
PreprocessedImage=$1
BrainMask=$2
T1Raw=$3
ResultRoot=$4
#PreprocessedImage=result/testing/raw-den-unr-mdc-unbiased.mif
#BrainMask=/Users/ningrongye/Desktop/python/MRI/TCB/Test_mrtrix/FSL_brainmask.mif
#T1Raw=data/FT_T1/
#ResultRoot=result/FiberEstimation/
if [ ! -d "${ResultRoot}" ]; then
	mkdir -p $ResultRoot
fi
# Response Function (RF) estimation
wm_rf=$ResultRoot/rf_wm.txt
gm_rf=$ResultRoot/rf_gm.txt
csf_rf=$ResultRoot/rf_csf.txt
  rf_voxels=$ResultRoot/rf-voxels.mif
  ## $rf_voxcels: those voxels which are selected for the response function estimation of each tissue type.
wm_fod=$ResultRoot/fod_wm.mif
gm_fod=$ResultRoot/fod_gm.mif
csf_fod=$ResultRoot/fod_csf.mif
  vfMap=$ResultRoot/fod_vf.mif
  ## Volume Fraction map
wm_fodnorm=$ResultRoot/fod_wm-norm.mif
gm_fodnorm=$ResultRoot/fod_gm-norm.mif
csf_fodnorm=$ResultRoot/fod_csf-norm.mif
  vfMap_norm=$ResultRoot/fod_vf-norm.mif

T1Use=$ResultRoot/T1-raw.mif
tt5_nocoreg=$ResultRoot/5tt-nocoreg.mif
  PreprocessedImage_name=`basename $PreprocessedImage`
  b0_mean=$ResultRoot/${PreprocessedImage_name%%.mif}-b0mean.nii.gz
  diff2struct_fsl=$ResultRoot/diff2struct-fsl.mat
  diff2struct_mrtrix=$ResultRoot/diff2struct-mrtrix.txt
  tt5_nocoreg_NotUnityMask=${tt5_nocoreg%%.mif}-NoUnityMask.mif
tt5_coreg=$ResultRoot/5tt-coreg.mif


dwi2response	dhollander \
		$PreprocessedImage \
		$wm_rf $gm_rf $csf_rf \
		-voxel $rf_voxels
## check if the voxel is correct:
mrview $PreprocessedImage -overlay.load $rf_voxels &
## check the Response Function
## if response function is a sphere, dwi is isotropic diffusion. 
shview $wm_rf & # should be anisotropic in b1000 ...
shview $gm_rf &

# Estimation of Fiber Orientation Distributions (FOD)
dwi2fod 	msmt_csd \
		$PreprocessedImage \
		-mask $BrainMask \
		$wm_rf $wm_fod \
		$gm_rf $gm_fod \
		$csf_rf $csf_fod
mrconvert -coord 3 0 $wm_fod - | mrcat $csf_fod $gm_fod - $vfMap
mrview $vfMap -odf.load_sh $wm_fod &
## check list:
## 1. if FOD could accurately resolve crossing fibers, e.g. by inspecting FOD estimation in locations known to contain crossing fibers by anatomy 
## 2. if wm_fod only performed within the borders of the white matter. 

# Intensity Normalization
## When you have multiple subjects, this step helps to make the FODs comparable between your subjects, by performing a global intensity normalization.
mtnormalise 	$wm_fod $wm_fodnorm \
		$gm_fod $gm_fodnorm \
		$csf_fod $csf_fodnorm \
		-mask $BrainMask
mrconvert -coord 3 0 $wm_fodnorm - | mrcat $csf_fodnorm $gm_fodnorm - $vfMap_norm
mrview $vfMap_norm -odf.load_sh $wm_fodnorm &

# Preparing Anatomically Constrained Tractography (ACT)
## 1. generating a five-tissue-type (5TT) segmented tissue image 
##	cortical gray matter, subcortical gray matter, white matter, CSF and pathological tissue
##	The fifth tissue(pathological tissue) can be optionally used to manually delineate regions of the brain where the architecture of the tissue present is unclear, and therefore the type of anatomical priors to be applied are also unknown. For any streamline entering such a region, no anatomical priors are applied until the streamline either exists that region, or stops due to some other streamlines termination criterion.
##	5TT can be edit using: **5ttedit**
##	more detail please check:
##	http://userdocs.mrtrix.org/en/latest/quantitative_structural_connectivity/act.html
##	BATMAN_tutorial.pdf: page 15
mrconvert $T1Raw $T1Use
5ttgen fsl $T1Use ${tt5_nocoreg}
# result 5tt_nocoreg contains 5 brain voxels with non-unity sum of partial volume fractions
5ttcheck $tt5_nocoreg -masks $tt5_nocoreg_NotUnityMask
mrview $tt5_nocoreg &
# not tested:
dwiextract $PreprocessedImage - -bzero | mrmath - mean ${b0_mean%%.nii.gz}.mif -axis 3
mrconvert ${b0_mean%%.nii.gz}.mif $b0_mean
tt5_nocoreg_nii=${tt5_nocoreg%%.mif}.nii.gz
mrconvert $tt5_nocoreg ${tt5_nocoreg_nii}
flirt 	-in $b0_mean \
	-ref $tt5_nocoreg_nii \
	-interp nearestneighbour \
	-dof 6 \
	-omat $diff2struct_fsl
transformconvert 	$diff2struct_fsl \
			$b0_mean $tt5_nocoreg_nii \
			flirt_import $diff2struct_mrtrix
mrtransform $tt5_nocoreg \
	    -linear $diff2struct_mrtrix \
	    -inverse $tt5_coreg
mrview  $PreprocessedImage \
	-overlay.load $tt5_nocoreg -overlay.colourmap 2 \
	-overlay.load $tt5_coreg -overlay.colourmap 1 &
