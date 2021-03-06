# original: https://github.com/ftyers/cross-lingual-parsing/blob/master/utils/treebanks_union.py

import os
import sys
import random
from conllu_parser import *

# enable for writing only the intersection of tbs that were included in MST voting
sample_treebanks = False

# random seeds used for these experiments
RANDOM_SEEDS=['54360','44184','20423','80520','27916']


def treebanks_dict(val_path):
    whole = {}
    for random_seed in RANDOM_SEEDS:
        for fname in treebanks:
            if str(random_seed) in fname:
                with open(val_path + '/' + fname) as f:
                    sents = f.read().split('\n\n')
                    # at this point, treebank has n sub-lists for each file,
                    # where n is a number of treebank versions

                    whole = one_treebank_dict(sents, whole)
        print('# union: ' + str(len(whole)))
        return whole


def one_treebank_dict(sents, whole):
    for sent in sents:
        s = Sentence(sent)
        for comment_line in s.comments:
            if comment_line.startswith('# sent_id = '):
                num = int(comment_line.split('=')[1].strip())
                if num not in whole:
                    whole[num] = [s]
                else:
                    whole[num].append(s)
                break
    return whole


def get_sample_sentences(val_path, sample_keys):
    d_sample_sentences = {}
    for fname in treebanks:
        with open(val_path + '/' + fname) as f:
            sents = f.read().split('\n\n')
            sampled = treebank_sentence_dict(fname, sents, d_sample_sentences, sample_keys)
    
    return d_sample_sentences


def treebank_sentence_dict(fname, sents, d_sample_sentences, sample_keys):
    for sent in sents:
        s = Sentence(sent)
        for comment_line in s.comments:
            if comment_line.startswith('# sent_id = '):
                num = int(comment_line.split('=')[1].strip())
                if str(num) in sample_keys:
                    if fname not in d_sample_sentences:
                        d_sample_sentences[fname] = [s]
                    else:
                        d_sample_sentences[fname].append(s)
                break
    return d_sample_sentences


def random_union(tbs):
    result = []
    for num in tbs:
        sent = random.choice(tbs[num])
        result.append(str(sent))
    return result


def unite_treebanks(tbs):
    pass
    # treebank.append([Sentence(s) for s in sents])


def fast_write_3_4(whole, random_seed):
    sample_sents = []
    three_sents = [[], [], []]
    four_sents = [[], [], [], []]
    
    for num in whole:
        sents = whole[num]
        if len(sents) == 3:
            three_sents[0].append(str(sents[0]))
            three_sents[1].append(str(sents[1]))
            three_sents[2].append(str(sents[2]))
        elif len(sents) == 4:
            sample_sents.append(str(num))
            four_sents[0].append(str(sents[0]))
            four_sents[1].append(str(sents[1]))
            four_sents[2].append(str(sents[2]))
            four_sents[3].append(str(sents[3]))
    
    print('# three_sents: ' + str(len(three_sents[0])))
    print('# four_sents: ' + str(len(four_sents[0])))
   
    with open(f'output/{model_type}/tmp/three_1st_{random_seed}.conllu', 'w') as f:
        f.write('\n\n'.join(three_sents[0]))
    with open(f'output/{model_type}/tmp/three_2nd_{random_seed}.conllu', 'w') as f:
        f.write('\n\n'.join(three_sents[1]))
    with open(f'output/{model_type}/tmp/three_3rd_{random_seed}.conllu', 'w') as f:
        f.write('\n\n'.join(three_sents[2]))
    with open(f'output/{model_type}/tmp/four_1st_{random_seed}.conllu', 'w') as f:
        f.write('\n\n'.join(four_sents[0]))
    with open(f'output/{model_type}/tmp/four_2nd_{random_seed}.conllu', 'w') as f:
        f.write('\n\n'.join(four_sents[1]))
    with open(f'output/{model_type}/tmp/four_3rd_{random_seed}.conllu', 'w') as f:
        f.write('\n\n'.join(four_sents[2]))
    with open(f'output/{model_type}/tmp/four_4th_{random_seed}.conllu', 'w') as f:
        f.write('\n\n'.join(four_sents[3]))
    
    with open(f'output/{model_type}/tmp/sample_sents.conllu', 'w') as f:
        f.write('\n'.join(sample_sents))
        

    if sample_treebanks == True:
        # extra logic to keep track of filenames and write matching sentences
        # can fix size of sample_sents to a certain number 

        sampled_names = get_sample_sentences(val_path, sample_sents)
        for k, v in sampled_names.items():
            sents = []
            #print(k)
            for sent in v:
                sents.append(str(sent))
            
            lang = k.split('-')[0]
            outfile = lang + '-sampled.conllu'

            #with open(f'output/{model_type}/tmp/{outfile}', 'w') as f:
            #    f.write('\n\n'.join(sents))


if __name__ == '__main__':

    # access relevant 'validated' directory
    model_type = str(sys.argv[1])
    val_path = os.path.join('output', model_type, 'validated')
    if not os.path.exists(val_path):
        print('cannot find validated folder at: {}'.format(val_path))

    # populate treebanks list with files in 'validated' folder
    treebanks = []

    for random_seed in RANDOM_SEEDS:
        for treebank in os.listdir(val_path):
            if 'fao_wiki.apertium' in treebank and str(random_seed) in treebank:
                print("found", treebank)
                treebanks.append(treebank)
    
        union = treebanks_dict(val_path)
        fast_write_3_4(union, random_seed)

    # tbs = treebanks_dict()
    # res = random_union(tbs)
    # with open('random_union.conllu', 'w') as f:
    #   f.write('\n\n'.join(res))
