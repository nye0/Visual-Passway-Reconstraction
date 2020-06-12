#!/bin/bash
#----------------------------------------------------------
# runing time
set StartTime = `date`;
set tSecStart = `date '+%s'`;
#----------------------------------------------------------


# get batch option edit based on [HCPpipline]()

get_batch_options(){
    	local arguments=("$@")
	local index=0
	local numArgs=${#arguments[@]}
	local argument

    	while [ ${index} -lt ${numArgs} ]; do
		argument=${arguments[index]}
		case ${argument} in
			--RawImage=*)
				RawImage=${argument#*=}
				index=$(( index + 1 ))
				;;
			--RawImage_PE=*)
				RawImage_PE=${argument#*=}
				index=$(( index + 1 ))
				;;
			--RPE=*)
				# should be pair|all|none
				# all: ALL DWIs have been acquired with opposing phase-encoding 
				# pair: Specify that a set of images (typically b=0 volumes) provided
				# none: no reversed phase-encoding image data is being provided;
				RPE=${argument#*=}
                                index=$(( index + 1 ))
                                ;;
			--RPE_Image=*)
				# 
				RPEImage=${argument#*=}
                                index=$(( index + 1 ))
                                ;;
			--ResultRoot=*)
				ResultRoot=${argument#*=}
                                index=$(( index + 1 ))
                                ;;
			*)
                echo ""
                echo "ERROR: Unrecognized Option: ${argument}"
                echo ""
                exit 1
                ;;
        esac
    done
}
get_batch_options "$@"
# check the input
#----------------------------------------------------------
if [ -n "${RawImage}" ]; then
	if [ -e "${RawImage}" ]; then
		echo RawImage: $RawImage
		((checked+=1))
	else
		echo RawImage Do not exist!
		exit
	fi
else
	echo Please set RawImage!
	exit
fi
PElist="RL LR PA AP IS SI"
if [ -n "${RawImage_PE}" ]; then
	if [[ " ${PElist} " =~ " ${RawImage_PE} " ]] ; then
		echo RawImage Phase-encoding: $RawImage_PE
	else
		echo RawImage_PE should be within $PElist!
		exit
	fi
else
	echo Please Set RawImage_PE!
	exit
fi
RPElist="pair all none"
if [ -n "${RPE}" ]; then
	if [[ " ${RPElist} " =~ " ${RPE} " ]] ; then
                echo Reversed Phase-encoding Image: $RPE
		if [[ "${RPE}" == "none" ]] ; then
			((checked+=1))
		else
			if [ -n "${RPEImage}" ]; then
				if [ -e "${RPEImage}" ]; then
			                echo Reversed Phase-encoding Image Path: $RPEImage
				else
					echo Reversed Phase-encoding Image do not exist!
					exit
				fi
			else
				echo Plese Set RPEImage!
				exit
			fi
		fi
	else
		echo RPE should be within $RPElist!
		exit
	fi
else
	echo Please Set RPE!
	exit
fi


if [ -n "${ResultRoot}" ]; then
	((checked+=1))
	echo ResultRoot: $ResultRoot
	if [ ! -d "${ResultRoot}" ]; then 
		mkdir -p ${ResultRoot}
	fi
else
	echo Please Set ResultRoot!
	exit
fi
#----------------------------------------------------------

# Var will be used
RawUse=$ResultRoot/raw.mif
den=${RawUse%%.mif}-den.mif
  noise=${RawUse%%.mif}-noise.mif
den_unr=${den%%.mif}-unr.mif

PrepImage=$den_unr
PrepImage_mdc=${PrepImage%%.mif}-mdc.mif
PreprocessedImage=${PrepImage_mdc%%.mif}-unbiased.mif
  bias=${PrepImage_mdc%%.mif}-bias.mif
BrainMask=${PreprocessedImage%%.mif}-unb.mif


#----------------------------------------------------------
b0mean_PE=$ResultRoot/b0mean_${RawImage_PE}.mif
rPE=${RawImage_PE:1:1}${RawImage_PE:0:1}
b0mean_rPE=$ResultRoot/b0mean_${rPE}.mif
b0mean_pair=$ResultRoot/b0mean_pair.mif

b0_pro(){
	dwiextract $PrepImage - -bzero | mrmath - mean $b0mean_PE -axis 3
	mrconvert $RPEImage - | mrmath - mean $b0mean_rPE -axis 3
	mrcat $b0mean_PE $b0mean_rPE -axis 3 $b0mean_pair
}

b0_script="echo Do not need to process b0!"
#----------------------------------------------------------

if [[ ${RPE} == "all" ]] ; then
	mrcat $RawImage $RPEImage $RawUse -axis 3
	b0_script="echo Do not neend"
	dwipreproc_opt="-rpe_all"
else
	mrconvert $RawImage $RawUse
	if [[ ${RPE} == "none" ]] ; then
		dwipreproc_opt="-rpe_none"
	else
		b0_script="b0_pro"
		dwipreproc_opt="-rpe_pair -se_epi $b0mean_pair"
	fi
fi
# Denoising

## from [manual](https://mrtrix.readthedocs.io/en/latest/dwi_preprocessing/denoising.html) 
## Patch size, 5x5x5 for data with <= 125 DWI volumes, 7x7x7 for data with <= 343 DWI volumes
dwidenoise $RawUse $den -noise $noise


#Unringing

## Note that this method is designed to work on images acquired with full
## k-space coverage. Running this method on partial Fourier ('half-scan')
## data may lead to suboptimal and/or biased results, as noted in the
## original reference below.
mrdegibbs $den $den_unr -axes 0,1

#Motion and distortion correction
${b0_script};
dwipreproc $PrepImage $PrepImage_mdc \
	-pe_dir ${RawImage_PE} \
	${dwipreproc_opt} \
	-eddy_option " --slm=linear"
#Bias field correction
dwibiascorrect -fsl $PrepImage_mdc $PreprocessedImage -bias $bias
#dwibiascorrect -ants $PrepImage_mdc $PreprocessedImage  -bias $bias

#Brain mask estimation
dwi2mask $PreprocessedImage $BrainMask
# dwibiascorrect can potentially deteriorate brain mask estimation!
# have to check with 
# mrview $PreprocessedImage -overlay.load $BrainMask

#----------------------------------------------------------
# runing time
set EndTime = `date`;
set tSecEnd = `date '+%s'`;
@ tSecRun = $tSecEnd - $tSecStart;
set tRunHours = `echo $tSecRun/3600|bc -l`
set tRunHours = `printf %6.3f $tRunHours`
echo "Started at $StartTime " 
echo "Ended   at $EndTime" 
echo "#@#%# run-time-hours $tRunHours" 
#----------------------------------------------------------
