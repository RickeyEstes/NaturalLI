# -- VARIABLES --
# (programs)
JAVAC=javac
SCALA_HOME=${HOME}/programs/scala
SCALAC=${SCALA_HOME}/bin/fsc
SCALA=${SCALA_HOME}/bin/scala
SCALADOC=${SCALA_HOME}/bin/scaladoc
# (locations)
SRC=src
TEST_SRC=test/src
LIB=lib
BUILD=classes
TEST_BUILD=test/bin
DIST=dist
TMP=tmp
DOC=scaladoc
# (classpaths)
JAVANLP=${JAVANLP_HOME}/projects/core/classes:${JAVANLP_HOME}/projects/more/classes:${JAVANLP_HOME}/projects/research/classes:${JAVANLP_HOME}/projects/scala-2.10/classes:${JAVANLP_HOME}/projects/scala-2.10/classes
CP=${JAVANLP}:lib/corenlp-scala.jar:lib/scripts/sim.jar:lib/scripts/jaws.jar:lib/scripts/trove.jar
# (C++ build path)
POSTGRES_I=/usr/include/postgresql/
POSTGRES_L=/usr/lib/postgresql/9.1/lib

check:
	ls ${POSTGRES_ROOT} | grep libpq-fe.h

# -- BUILD --
${DIST}/truth.jar: $(wildcard src/org/goobs/truth/*.scala) $(wildcard src/org/goobs/truth/*.java) $(wildcard src/org/goobs/truth/scripts/*.scala) $(wildcard src/org/goobs/truth/conf/*.conf)
	@mkdir -p ${BUILD}
	@echo "Compiling (${JAVAC})..."
	@${JAVAC} -d ${BUILD} -cp ${CP}:${SCALA_HOME}/lib/scala-library.jar:${SCALA_HOME}/lib/typesafe-config.jar `find ${SRC} -name "*.java"`
	@echo "Compiling (${SCALAC})..."
	@${SCALAC} -feature -deprecation -d ${BUILD} -cp ${CP} `find ${SRC} -name "*.scala"` `find ${SRC} -name "*.java"`
	cp ${SRC}/org/goobs/truth/conf/* ${BUILD}/
	@mkdir -p ${DIST}
	jar cf ${DIST}/truth.jar -C $(BUILD) .
	jar uf ${DIST}/truth.jar -C $(SRC) .

${DIST}/server: $(wildcard src/*.cc) $(wildcard src/*.h)
	@mkdir -p ${BUILD}
	@mkdir -p ${DIST}
	g++ -ggdb -I`pg_config --includedir` `find ${SRC} -name "*.h"` `find ${SRC} -name "*.cc"` -L`pg_config --libdir` -lpq -o ${DIST}/server 

doc:
	@echo "Documenting (${SCALADOC})..."
	mkdir -p ${DOC}
	@${SCALADOC} -d ${DOC} -cp ${CP} `find ${SRC} -name "*.scala"` `find ${SRC} -name "*.java"`

# -- TARGETS --
default: ${DIST}/concept.jar

run: ${DIST}/concept.jar
	./run


clean:
	rm -rf ${BUILD}
	rm -rf ${TEST_BUILD}
	rm -f ${DIST}/truth.jar
	rm -f ${DIST}/server
	rm -f java.hprof.txt
