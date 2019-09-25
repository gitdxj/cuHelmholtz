CFLAGS=-O2 -L../likefftwall -I../likefftwall
GFLAGS=-arch sm_35
LDFLAGS=-lcudasymmfft -lcufft -lcuTranspose
CCFLAGS=$(CFLAGS) $(GFLAGS)
SOLVER=cuda_helmholtz_solver.cu 

t:t.cu $(SOLVER)
	nvcc $(CCFLAGS) -o $@ $^ $(LDFLAGS)
trectangle:trectangle.cu $(SOLVER)
	nvcc $(CCFLAGS) -o $@ $^ $(LDFLAGS)

cpu:
	g++ -o testcpu -O2 testcpu.cpp hw3crt_wrapper.cpp -lgfortran -L. -lfishpack
cpurectangle:
	g++ -o testcpurectangle -O2 testcpurectangle.cpp hw3crt_wrapper.cpp -lgfortran -L. -lfishpack

clean:
	rm -fr t trectangle testcpu testcpurectangle
