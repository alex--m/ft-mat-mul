#!/bin/bash

# This script downloads and builds the required packages.
# If the packages are already built, try running the following:
#> cat build.sh | egrep "(cd|export)"

set -e
echo "Please make sure MPI executables are in PATH..."
which mpicc
which mpicxx
which mpif90
which mpirun

export FORT=gfortran
which $(FORT)

# OpenBLAS
# ========
git clone https://github.com/xianyi/OpenBLAS.git
cd OpenBLAS
make FC=$(FORT) -j
export OPENBLAS=`pwd`/libopenblas.a
cd ..

# ScaLAPACK
# =========
# *assumes MPI availability, preferably built with the same ifort:
# 	CC=icc FC=ifort F77=ifort CXX=icpc ./configure
svn co https://icl.cs.utk.edu/svn/scalapack-dev/scalapack/trunk && mv trunk ScaLAPACK
cd ScaLAPACK
cp SLmake.inc.example SLmake.inc
echo "BLASLIB=\$(OPENBLAS)" >> SLmake.inc
echo "LAPACKLIB=\$(OPENBLAS)" >> SLmake.inc
make
export SCALAPACK=`pwd`/libscalapack.a
cd ..

# Benchmark
# =========
cd benchmark
mpicxx *.cpp $SCALAPACK $OPENBLAS -l$FORT -o matrixmultiply
mpirun matrixmultiply
cd ..

# FT-LA (by UTK's ICL group)
# ==========================
wget http://icl.cs.utk.edu/projectsfiles/ft-la/software/ftla-rSC13.tgz
tar -xzf ftla-rSC13.tgz
cd ftla-rSC13
sed -i.bak "s/-lscalapack -llapack -lgotoblas2/\$(SCALAPACK) \$(OPENBLAS)/" Makefile
make
cd ..