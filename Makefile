TARGET	= libmatmult.so
LIBSRCS	= 
LIBOBJS	= matmult.cu

OPT	= -g -arch=sm_20
PIC	= -Xcompiler -fpic
XOPTS = -Xptxas=-v

CXX	= nvcc
CXXFLAGS = $(OPT) $(PIC) $(XOPTS)

CUDA_PATH ?= /appl/cuda/6.5
INCLUDES = -I$(CUDA_PATH)/include -I$(CUDA_PATH)/samples/common/inc

SOFLAGS = -shared
XLIBS	= -lcublas

$(TARGET): $(LIBOBJS)
	$(CXX) -o $@ $(CXXFLAGS) $(SOFLAGS) $(INCLUDES) $(LIBOBJS) $(XLIBS)

.SUFFIXES: .cu
.cu.o:
	$(CXX) -o $*.o -c $*.cu $(CXXFLAGS) $(SOFLAGS) $(INCLUDES)

clean:
	@/bin/rm -f *.so core

realclean: clean
	@/bin/rm -f $(TARGET)