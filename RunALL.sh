#!/bin/bash
# Make shell script for converting VOC to COCO format

# Usage: ./Convert2CoCo.sh <VOC_dir> <COCO_dir>
# Make new dicrectory for COCO format
# 3 below folders need to be modified to fit your own path
COCO="COLOR_5K_COCO"
VOC="COLOR_5K_VOC"
label="label_color.txt"

# Check if folder already exists
if [ ! -d $COCO ]; then
  # Create the new folder
  mkdir $COCO

  # Print message to confirm the folder was created
  echo "Successfully created $COCO"
else
  # Print message if folder already exists
  echo "Folder $COCO already exists"
fi

# Make sub folder inside COCO : <COCO_dir>/annotations
anotation="annotations"

# Check if folder already exists
if [ ! -d $COCO/$anotation ]; then
  # Create the new folder
  mkdir $COCO/$anotation

  # Print message to confirm the folder was created
  echo "Successfully created $COCO/$anotation"
else
  # Print message if folder already exists
  echo "Folder $COCO/$anotation already exists"
fi


train="train"
val="val"
test="test"
back=".."


# Copy all files from VOC to COCO
cp -r $VOC/$train $COCO
cp -r $VOC/$val $COCO
cp -r $VOC/$test $COCO

# Check if folder already exists
if [ ! -d ./voc2coco ]; then
  # Create the new folder
  git clone https://github.com/tuanmanh1410/voc2coco.git
  cd ./voc2coco

  # Print message to confirm the folder was created
  echo "Successfully cloned voc2coco"
else
  # Print message if folder already exists
  echo "Folder voc2coco already exists"
  cd ./voc2coco
fi

# Make empty file path first 
> train_path.txt
> val_path.txt
> test_path.txt

# Get file path
python Get_FilePath.py $back/$VOC/$train xml ./train_path.txt
python Get_FilePath.py $back/$VOC/$val xml ./val_path.txt
python Get_FilePath.py $back/$VOC/$test xml ./test_path.txt

# Convert VOC to COCO
python voc2coco.py --ann_paths_list ./train_path.txt --labels $label --output $back/$COCO/$anotation/train.json
python voc2coco.py --ann_paths_list ./val_path.txt --labels $label --output $back/$COCO/$anotation/val.json
python voc2coco.py --ann_paths_list ./test_path.txt --labels $label --output $back/$COCO/$anotation/test.json

# Remove xml file in COCO path
python remove_files.py $back/$COCO/$train xml
python remove_files.py $back/$COCO/$val xml
#python remove_files.py $back/$COCO/$test xml

# Move to main folder
cd ..

# Training DETR
# Make shell script for training Custom Dataset

COCO_TRAIN="../COLOR_5K_COCO"
NUM_CLASSES=7
NUM_EPOCHS=2
BATCH_SIZE=2
NUM_GPU=4
OUTPUT="outputs_color"
CHECK_POINT="best.pth"

# Check if main folder already exists
if [ ! -d ./detr_Egg_Detection ]; then
  # Create the new folder
  git clone https://github.com/tuanmanh1410/detr_Egg_Detection.git
  cd ./detr_Egg_Detection

  # Print message to confirm the folder was created
  echo "Successfully cloned voc2coco"
else
  # Print message if folder already exists
  echo "Folder DETR already exists"
  cd ./detr_Egg_Detection
fi

python Get_checkpoint.py

python -m torch.distributed.launch --nproc_per_node=$NUM_GPU --use_env main.py --coco_path $COCO_TRAIN --resume ./detr-r50_no-class-head.pth \
--batch_size $BATCH_SIZE --num_classes $NUM_CLASSES --output_dir $OUTPUT --epochs $NUM_EPOCHS

python final_evaluate.py --coco_path $COCO_TRAIN --batch_size $BATCH_SIZE --num_classes $NUM_CLASSES --resume $OUTPUT/$CHECK_POINT --detail True