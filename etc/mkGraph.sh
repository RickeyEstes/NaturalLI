#!/bin/bash
#
set -e
  
VOCAB=vocab.tab
SENSE=sense.tab
PRIV=privative.tab

GENERIC_TMP=`mktemp`

#
# Create vocabulary
#
echo "Creating vocabulary (in $VOCAB)..."
TMP=`mktemp`
cat graphData/lemma_sense_synset_defn.txt |\
  awk -F'	' '{ print $1 }' |\
  sed -e 's/_/ /g' > $TMP

zcat graphData/glove.6B.50d.txt.gz |\
  awk '{ print $1 }' >> $TMP

cat $TMP | sort | uniq |\
  awk '{printf("%d\t%s\n", NR + 63, $0)}' > $VOCAB
rm $TMP

#
# Create sense mapping
#
echo "Creating sense mapping (in $SENSE)..."

cat graphData/lemma_sense_synset_defn.txt |\
  awk -F'	' '{ print $1 "\t" $2 "\t" $4 }' |\
  sed -e 's/_/ /g' |\
  awk -F'	' '
      FNR == NR {
          assoc[ $2 ] = $1;
          next;
      }
      FNR < NR {
          if ( $1 in assoc ) {
              $1 = assoc[ $1 ]
          }
          print $1 "\t" $2 "\t" $3
      }
  ' $VOCAB - > $SENSE

#
# Create privatives
#
echo "Creating privatives (in $PRIV)..."
PRIVATIVE_WORDS=`echo "^(" \
     "believed|" \
     "debatable|" \
     "disputed|" \
     "dubious|" \
     "hypothetical|" \
     "impossible|" \
     "improbable|" \
     "plausible|" \
     "putative|" \
     "questionable|" \
     "so called|" \
     "supposed|" \
     "suspicious|" \
     "theoretical|" \
     "uncertain|" \
     "unlikely|" \
     "would - be|" \
     "apparent|" \
     "arguable|" \
     "assumed|" \
     "likely|" \
     "ostensible|" \
     "possible|" \
     "potential|" \
     "predicted|" \
     "presumed|" \
     "probable|" \
     "seeming|" \
     "anti|" \
     "fake|" \
     "fictional|" \
     "fictitious|" \
     "imaginary|" \
     "mythical|" \
     "phony|" \
     "false|" \
     "artificial|" \
     "erroneous|" \
     "mistaken|" \
     "mock|" \
     "pseudo|" \
     "simulated|" \
     "spurious|" \
     "deputy|" \
     "faulty|" \
     "virtual|" \
     "doubtful|" \
     "erstwhile|" \
     "ex|" \
     "expected|" \
     "former|" \
     "future|" \
     "onetime|" \
     "past|" \
     "proposed" \
     ")	[0-9]+" | sed -e 's/| /|/g'`

cat graphData/edge_*.txt |\
  sed -e 's/_/ /g' |\
  awk -F'	' '{ print $1 "\t" $2 }' |\
  egrep "$PRIVATIVE_WORDS" |\
  sort | uniq |\
  sed -e 's/_/ /g' |\
  awk -F'	' '
      FNR == NR {
          assoc[ $2 ] = $1;
          next;
      }
      FNR < NR {
          if ( $1 in assoc ) {
              $1 = assoc[ $1 ]
          }
          print
      }
  ' $VOCAB - | sed -e 's/ /\t/g' > $PRIV

#
# Creating edge types
#
echo "Creating edge types (in edgeTypes.tab)..."
TMP=`mktemp`
for file in `find graphData -name "edge_*.txt"`; do
  echo $file |\
    sed -r -e 's/.*\/edge_(.*)_[anrvs].txt/\1/g' |\
    sed -r -e 's/.*\/edge_(.*).txt/\1/g'
done > $TMP
echo "quantifier_up" >> $TMP
echo "quantifier_down" >> $TMP
echo "quantifier_negate" >> $TMP
echo "quantifier_reword" >> $TMP
echo "angle_nn" >> $TMP
cat $TMP | sort | uniq | awk '{ printf("%d\t%s\n", NR - 1, $0) }' > edgeTypes.tab
rm $TMP

#
# Create graph
#
function index() {
  FILE=`mktemp`
  cat $1 | sort | uniq | sed -e 's/_/ /g' > $FILE
  awk -F'	' '
      FNR == NR {
          assoc[ $2 ] = $1;
          next;
      }
      FNR < NR {
          for ( i = 1; i <= NF; i+=2 ) {
              if ( $i in assoc ) {
                  $i = assoc[ $i ]
              }
          }
          print
      }
  ' $VOCAB $FILE |\
    sed -e 's/ /\t/g'
  rm $FILE
}

function indexAll() {
  for file in `find graphData -name "edge_*.txt"`; do
    type=`echo $file |\
      sed -r -e 's/.*\/edge_(.*)_[anrvs].txt/\1/g' |\
      sed -r -e 's/.*\/edge_(.*).txt/\1/g'`
    modFile="$file"
    if [ "$type" == "antonym" ]; then
      modFile="$GENERIC_TMP"
      cat $file > $modFile
      cat $file | awk -F'	' '{ print $3 "\t" $4 "\t" $1 "\t" $2 "\t" $5 }' >> $modFile
    fi
    index $modFile | sed -e "s/^/$type	/g" |\
      awk '
        FNR == NR {
            assoc[ $2 ] = $1;
            next;
        }
        FNR < NR {
          $1 = assoc[ $1 ];
          print $2 " " $3 " " $4 " " $5 " " $1 " " $6
        } ' edgeTypes.tab - |\
      sed -e 's/ /	/g'
  done
}

echo "Indexing edges..."
indexAll | gzip > graph.tab.gz
echo "DONE"

rm -f $VOCAB.gz
gzip $VOCAB
rm -f $SENSE.gz
gzip $SENSE
rm -f $PRIV.gz
gzip $PRIV

rm -f $GENERIC_TMP