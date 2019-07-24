#!/usr/bin/env bash

# usage: ./scripts/predict_source_model.sh monolingual pos ud dev
# if using files wihout annotations use: --overrides '{"dataset_reader": {"disable_dependencies": true}}'

test -z $1 && echo "Missing model type: 'monolingual' or 'multilingual'"
test -z $1 && exit 1
model_type=$1

test -z $2 && echo "Missing task type: 'pos' or 'parse'"
test -z $2 && exit 1
task_type=$2

test -z $3 && echo "Missing file type: 'ud' or 'user'"
test -z $3 && exit 1
file_type=$3

test -z $4 && echo "Missing data type: 'dev' or 'test'"
test -z $4 && exit 1
data_type=$4

echo "user specified task type: ${task_type} for a ${model_type} model"

TB_DIR='data/ud-treebanks-v2.2'
TIMESTAMP=`date "+%Y%m%d-%H%M%S"`

for lang in dan swe nno nob; do
  # assign tbid to language
  if [ "${lang}" = "dan" ]; then
    tbid=da_ddt
  elif [ "${lang}" = "swe" ]; then
    tbid=sv_talbanken
  elif [ "${lang}" = "nno" ]; then
    tbid=no_nynorsk
  elif [ "${lang}" = "nob" ]; then
    tbid=no_bokmaal
  fi
  
  echo "processing ${tbid}..."

  #=== UD treebank ===
  if [ "${file_type}" == 'ud' ]; then
    echo "tagging UD treebank"

    # find the appropriate UD treebank
    for filepath in ${TB_DIR}/*/${tbid}-ud-train.conllu; do
      dir=`dirname $filepath`
      tb_name=`basename $dir`

      PRED_FILE=${TB_DIR}/${tb_name}/${tbid}-ud-${data_type}.conllu
      OUT_FILE=output/${model_type}/predicted/${tbid}-${task_type}.conllu
    done
    fi

  #=== Model type ===
  if [ "${model_type}" == 'monolingual' ]; then
    src=${tbid}-${task_type}
  elif [ "${model_type}" == 'multilingual' ]; then
    src=da_sv_no-${task_type}
  fi

  #== POS ===
  if [ "${task_type}" == 'pos' ]; then
    echo "predicting pos"
    PREDICTOR='sentence-tagger'

    #=== Custom filepath ===
    if [ "${file_type}" == 'user' ]
      then echo "tagging user-created file with custom paths/name"
      
      # path to source udpipe segmented/tokenized file to predict
      PRED_FILE=data/faroese/fao_wiki.apertium.fao-${lang}.udpipe.parsed.conllu

      if [ "${model_type}" == 'multiingual' ]; then
        # change name to format expected by dataset reader
        cp ${PRED_FILE} data/faroese/${tbid}-udpipe.parsed.conllu
        PRED_FILE=data/faroese/${tbid}-udpipe.parsed.conllu
      fi
    fi

  elif [ "${task_type}" == 'parse']; then
    echo "predicting parse"
    PREDICTOR=biaffine-dependency-parser-monolingual
    
    PRED_FILE=output/${model_type}/predicted/${tbid}-pos.conllu # AllenNLP tagged file
      
    # file to write
    OUT_FILE=output/${model_type}/predicted/fao_wiki.apertium.fao-${tbid}.allennlp.parsed.conllu
fi   

#=== Predict ===
allennlp predict output/${model_type}/source_models/${src}/model.tar.gz ${PRED_FILE} \
   --output-file ${OUT_FILE} \
   --predictor ${PREDICTOR} \
   --include-package library \
   --use-dataset-reader

done

