#!/bin/bash
set -e
echo "Please make sure MPI executables are in PATH..."
which mpicc
which mpicxx
which mpif90
which mpirun

export FORT=gfortran
which $(FORT)

# BLAS
# ====
wget http://www.netlib.org/blas/blas.tgz
tar xzvf blas.tgz
mv BLAS-* BLAS
pushd BLAS
make -j
export BLAS=`pwd`/blas_LINUX.a
popd

# CBLAS
# =====
http://www.netlib.org/blas/blast-forum/cblas.tgz
tar xzvf cblas.tgz
pushd CBLAS
cp Makefile.LINUX Makefile.in
echo "BLLIB = \$(BLAS)" >> Makefile.in
make -j
export CBLAS=`pwd`/lib/cblas_LINUX.a
popd

# LAPACK
# ======
svn co https://icl.cs.utk.edu/svn/lapack-dev/lapack/trunk && mv trunk LAPACK
pushd LAPACK
cp INSTALL/make.inc.$(FORT) make.inc
echo "BLASLIB=\$(BLAS)" >> make.inc
echo "CBLASLIB=\$(CBLAS)" >> make.inc
make -j lapacklib
make clean
export LAPACK=`pwd`/liblapack.a
popd


# ScaLAPACK
# =========
# *assumes MPI availability, preferably built with the same ifort:
# 	CC=icc FC=ifort F77=ifort CXX=icpc ./configure
svn co https://icl.cs.utk.edu/svn/scalapack-dev/scalapack/trunk && mv trunk ScaLAPACK
pushd ScaLAPACK
cp SLmake.inc.example SLmake.inc
echo "BLASLIB=\$(BLAS)" >> SLmake.inc
echo "LAPACKLIB=\$(LAPACK)" >> SLmake.inc
make
export SCALAPACK=`pwd`/libscalapack.a
popd


# Benchmark
# =========
pushd benchmark
mpicxx *.cpp $(SCALAPACK) $(LAPACK) $(CBLAS) $(BLAS) -l$(FORT) -o matrixmultiply
mpirun matrixmultiply
popd

# FT-LA (by UTK's ICL group)
# ==========================
wget http://icl.cs.utk.edu/projectsfiles/ft-la/software/ftla-rSC13.tgz
tar -xzf ftla-rSC13.tgz
cd ftla-rSC13