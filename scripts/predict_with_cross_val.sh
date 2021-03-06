#!/bin/bash

test -z $1 && echo "Missing data type: 'train' or 'dev'"
test -z $1 && exit 1
data_type=$1

GLD_DIR='data/ud-treebanks-v2.2'
TMP_DIR='data/tmp'
TB_DIR='data/ud-treebanks-v2.2-crossfold-tags'

TIMESTAMP=`date "+%Y%m%d-%H%M%S"` 
SUFFIX='-20190804-193214'
PREDICTOR='conllu-predictor'

if [ ${data_type} == 'train' ]
  then echo "precdicting monolingual model(s) on training splits..."

  for RANDOM_SEED in 54360 44184 20423 80520 27916; do  
    for tbid in da_ddt sv_talbanken no_nynorsk no_bokmaal; do
      for split in 0 1 2 3 4 5 6 7 8 9; do
          for filepath in ${GLD_DIR}/*/${tbid}-ud-train.conllu; do
              dir=`dirname $filepath`
              tb_name=`basename $dir`

              mkdir -p ${TMP_DIR}/${tb_name}

			  PRED_FILE=${TMP_DIR}/${tb_name}/${tbid}-ud-dev.conllu.split-${split}
			  OUT_FILE=${TMP_DIR}/${tb_name}/${tbid}-ud-dev.conllu.split-${split}-predicted-${RANDOM_SEED} 

              # source model to predict
			  src=${tbid}-split-${split}-${RANDOM_SEED}

			  #=== Predict ===
			  allennlp predict output/monolingual/cross_val/${src}/model.tar.gz ${PRED_FILE} \
   				--output-file ${OUT_FILE} \
   				--predictor ${PREDICTOR} \
   				--include-package library \
   				--use-dataset-reader

              # append the predictions of the splits to the training file 
              cat ${TMP_DIR}/${tb_name}/${tbid}-ud-dev.conllu.split-${split}-predicted-${RANDOM_SEED} >> ${TMP_DIR}/${tb_name}/${tbid}-ud-train-${RANDOM_SEED}.conllu
    done
  done

  cp ${TMP_DIR}/${tb_name}/${tbid}-ud-train-${RANDOM_SEED}.conllu ${TB_DIR}/${tb_name}/${tbid}-ud-train-${RANDOM_SEED}.conllu
done
done

elif [ ${data_type} == 'dev' ]
  then echo "predicting on dev set using fully trained model..."

  for RANDOM_SEED in 54360 44184 20423 80520 27916; do  
    for tbid in da_ddt sv_talbanken no_nynorsk no_bokmaal; do
      for filepath in ${GLD_DIR}/*/${tbid}-ud-train.conllu; do
        dir=`dirname $filepath`
        tb_name=`basename $dir`
     
        PRED_FILE=${GLD_DIR}/${tb_name}/${tbid}-ud-dev.conllu
      
        OUT_FILE=${TB_DIR}/${tb_name}/${tbid}-ud-dev-${RANDOM_SEED}.conllu

        # source model
        src=${tbid}-pos-${RANDOM_SEED}
      
        #=== Predict ===
        allennlp predict output/monolingual/source_models/${src}/model.tar.gz ${PRED_FILE} \
          --output-file ${OUT_FILE} \
          --predictor ${PREDICTOR} \
          --include-package library \
          --use-dataset-reader
      
      done
    done
  done
fi
