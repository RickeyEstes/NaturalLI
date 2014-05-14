#!/usr/bin/env bash
#

set -e
export MAXMEM_GB=6
export JAVANLP_HOME=${JAVANLP_HOME-/home/gabor/workspace/nlp}
echo "JavaNLP at: $JAVANLP_HOME"
export SCALA_HOME=${SCALA_HOME-/home/gabor/programs/scala}
echo "Scala at: $SCALA_HOME"

echo "-- SETUP --"
rm lib/stanford-corenlp-*
ln -s $HOME/stanford-corenlp-* lib/

echo "-- CLEAN --"
make distclean
git clean -f
./autogen.sh
autoreconf

echo "-- MAKE --"
./configure \
  --with-scala=$SCALA_HOME \
  --with-java=/usr/lib/jvm/java-7-oracle \
  --enable-debug
make clean
make all check TESTS_ENVIRONMENT=true 

echo "-- C++ TESTS --"
test/src/test_server --gtest_output=xml:test/test_server.junit.xml
test/src/itest_server --gtest_output=xml:test/itest_server.junit.xml

echo "-- C++SPECIAL TESTS --"
echo "(high memory mode)"
make clean
./configure \
  --with-scala=$SCALA_HOME \
  --with-java=/usr/lib/jvm/java-7-oracle \
  --enable-debug \
  HIGH_MEMORY=true
make all check
echo "(no debugging)"
make clean
./configure \
  --with-scala=$SCALA_HOME \
  --with-java=/usr/lib/jvm/java-7-oracle
make all check

echo "-- JAVA TESTS --"
make java_test

echo "-- COVERAGE --"
cd src/
rm -f naturalli_server-Messages.pb.gcda
rm -f naturalli_server-Messages.pb.gcno
rm -f naturalli_server-Messages.pb.h.gcno
rm -f naturalli_server-Messages.pb.h.gcda
gcovr -r . --html --html-details -o /var/www/naturalli/coverage/index.html
gcovr -r . --xml -o coverage.xml
cd ..

echo "-- DOCUMENT --"
doxygen doxygen.conf

echo "SUCCESS!"
exit 0
