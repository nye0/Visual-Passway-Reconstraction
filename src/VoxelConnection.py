import sys,os
import SimpleITK as sitk
from subprocess import call

RawROIPath=sys.argv[1]
#ROIUsePath=sys.argv[2]
ResultRoot=sys.argv[2]  #os.path.dirname(ROIUsePath)
Tracks=sys.argv[3]
TrackedROIName=sys.argv[4]
vector_txt=os.path.join(ResultRoot,TrackedROIName+'-vector.txt')
ROIFinial_temp=os.path.join(ResultPath,TrackedROIName+'.nii.gz')
ROIFinial=os.path.join(ResultPath,TrackedROIName+'.mif')


ROIFileName=os.path.basename(RawROIPath)



if RawROIPath.split('.')[-1]=='mif':
    OutputROIName='.'.join(ROIFileName.split('.')[:-1])+'-Parcellation.mif'
    ROIPath='.'.join(RawROIPath.split('.')[:-1]+['nii.gz'])
    call(["mrconvert",RawROIPath,ROIPath])
else:
    OutputROIName='.'.join(ROIFileName.split('.')[:-2])+'-Parcellation.mif'
    # default RawROIfile postfix should be nii.gz 
    ROIPath=RawROIPath
ROIUsePath=os.path.join(ResultRoot,OutputROIName)
ROIUsePath_temp='.'.join(ROIUsePath.split('.')[:-1]+['nii.gz'])

if not os.path.exists(ResultRoot):
    os.makedirs(ResultRoot)


# parcellation ROI

Mask0=sitk.ReadImage(ROIPath,sitk.sitkFloat64)
Mask0_array=sitk.GetArrayFromImage(Mask0)
Mask0_array[Mask0_array>0]=list(range(1,len(Mask0_array[Mask0_array>0])+1))
Mask1=sitk.GetImageFromArray(Mask0_array)
if Mask1.GetSize()==Mask0.GetSize():
    Mask1.CopyInformation(Mask0)
else:
    print("Image Size Changed, Please check!")
    exit
sitk.WriteImage(Mask1,ROIUsePath_temp)
call(["mrconvert",ROIUsePath_temp,ROIUsePath])

# compute each voxel's connection value

call(['tck2connectome','-vector',
      Tracks, ROIUsePath,
      vector_txt])
with open(vector_txt,'r') as f:
    vector_list=[float(i) for i in f.read().strip().split(' ')]
Mask0_array[Mask0_array>0]=vector_list
MaskTracked=sitk.GetImageFromArray(Mask0_array)
MaskTracked.CopyInformation(Mask0)
sitk.WriteImage(MaskTracked,ROIFinial_temp)
call(["mrconvert",ROIFinial_temp,ROIFinial])

