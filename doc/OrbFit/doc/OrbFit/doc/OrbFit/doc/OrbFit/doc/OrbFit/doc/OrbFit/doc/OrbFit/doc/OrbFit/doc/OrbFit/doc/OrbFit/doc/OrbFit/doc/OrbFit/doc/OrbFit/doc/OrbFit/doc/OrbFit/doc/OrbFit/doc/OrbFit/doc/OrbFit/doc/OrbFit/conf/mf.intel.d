# Makefile options for the INTEL compiler,not  optimized

# Fortran compiler
FC=ifc
# Options for Fortran compiler for debugging:
FFLAGS=  -cm -g -C -Vaxlib -I../include 
# "ranlib" command: if it is not needed, use "RANLIB=touch"
RANLIB=ranlib
VPATH=../include

