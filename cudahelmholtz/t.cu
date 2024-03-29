#include "hw3crt_wrapper.h"
#include <iostream>
#include <cstdlib>
#include <cstdio>
#include <cmath>
#include "time_.h"
#include "cuda_helmholtz_solver.h"

#define PI 3.14159265358979323846
//#define DEBUG

using namespace std;

int main(int argc, char **argv)
{
	if (argc < 5)
	{
		printf("usage: ./t N xbc ybc zbc\n");
		exit(-1);
	}
	int N = atoi(argv[1]);
	int xbc = atoi(argv[2]);
	int ybc = atoi(argv[3]);
	int zbc = atoi(argv[4]);
	int nx=N; 
	int ny=N;
	int nz=N;
	int i, j, k;
	double dx = 1.0/nx;
	double dy = 1.0/ny;
	double dz = 1.0/nz;
	int sz = (nx+1)*(ny+1)*(nz+1);
	double *f =  new double[sz];
	double *bcl=NULL;
	double *bcr=NULL;
	double *bcb=NULL;
	double *bct=NULL;
	double *bcf=NULL;
	double *bce=NULL;

	if ( xbc == 3 || xbc == 4 )
		bcl = (double *) malloc(sizeof(double)*(ny+1)*(nz+1));
	if ( xbc == 3 || xbc == 2 )
		bcr = (double *) malloc(sizeof(double)*(ny+1)*(nz+1));
	if ( ybc == 3 || ybc == 4 )
		bcb = (double *) malloc(sizeof(double)*(nx+1)*(nz+1));
	if ( ybc == 3 || ybc == 2 )
		bct = (double *) malloc(sizeof(double)*(nx+1)*(nz+1));
	if ( zbc == 3 || zbc == 4 )
		bcf = (double *) malloc(sizeof(double)*(nx+1)*(ny+1));
	if ( zbc == 3 || zbc == 2 )
		bce = (double *) malloc(sizeof(double)*(nx+1)*(ny+1));

	//D
	for (k=0; k<nz+1; k++)
		for (j=0; j<ny+1; j++)
			for (i=0; i<nx+1; i++)
				f[k*(nx+1)*(ny+1)+j*(nx+1)+i] = 
					(-1./3-4*PI*PI)*sin(2*PI*i*dx)*sin(2*PI*j*dy)*sin(2*PI*k*dz);
	//				(-1./3-4*PI*PI)*cos(2*PI*i*dx)*cos(2*PI*j*dy)*cos(2*PI*k*dz);
					// - (i*dx)*(i*dx) - (j*dy)*(j*dy);
	//f[100]+=0.1;
	for (k=0; k<nz+1; k++)
		for (j=0; j<ny+1; j++)
		{
			double temp = 2. * PI / 3. * sin(2*PI*j*dy) * sin(2*PI*k*dz);
			//double temp = 0.;
			if ( xbc == 3 || xbc == 4 )
				bcl[k*(ny+1)+j] = temp;// k*dz*k*dz + j*dy*j*dy +0;
			if ( xbc == 3 || xbc == 2 )
				bcr[k*(ny+1)+j] = temp;// k*dz*k*dz + j*dy*j*dy +1;
		}
////			f[k*(nx+1)*(ny+1)+j*(nx+1)+0] 
////				= k*dz*k*dz + j*dy*j*dy +0;
////			f[k*(nx+1)*(ny+1)+j*(nx+1)+nx]
////				= k*dz*k*dz + j*dy*j*dy +1;
//		}

	for (k=0; k<nz+1; k++)
		for (i=0; i<nx+1; i++)
		{
			double temp = 2. * PI / 3. * sin(2*PI*i*dx) * sin(2*PI*k*dz);
			//double temp = 0.;
			if ( ybc == 3 || ybc == 4 )
				bcb[k*(nx+1)+i] = temp;// k*dz*k*dz + j*dy*j*dy +0;
			if ( ybc == 3 || ybc == 2 )
				bct[k*(nx+1)+i] = temp;// k*dz*k*dz + j*dy*j*dy +1;
	//		f[k*(nx+1)*(ny+1)+0*(nx+1)+i] = 0;
	//			= k*dz*k*dz + i*dx*i*dx +0;
	//		f[k*(nx+1)*(ny+1)+ny*(nx+1)+i] = 0; 
	//			= k*dz*k*dz + i*dx*i*dx +1;
		}

	for (j=0; j<ny+1; j++)
		for (i=0; i<nx+1; i++)
		{
			double temp = 2. * PI / 3. * sin(2*PI*i*dx) * sin(2*PI*j*dy);
			//double temp = 0.;
			if ( zbc == 3 || zbc == 4 )
				bcf[j*(nx+1)+i] = temp;// k*dz*k*dz + j*dy*j*dy +0;
			if ( zbc == 3 || zbc == 2 )
				bce[j*(nx+1)+i] = temp;// k*dz*k*dz + j*dy*j*dy +1;
		}

#ifdef DEBUG1
	for (k=0; k<=nz; k++)
	{
		for (j=0; j<=ny; j++)
		{
			for (i=0; i<=nx; i++)
			{
				printf("%.14f\t", f[k*(nx+1)*(ny+1)+j*(nx+1)+i]);
				//printf("%.14f\t", (f[i+1]-f[i-1])/2./dx);
				//if (i%5 == 4)
				//	printf("\n");
			}
			printf("\n");
		}
		printf("\n");
	}
#endif

	double *f_d;
	double *bcl_d=NULL;
	double *bcr_d=NULL;
	double *bcb_d=NULL;
	double *bct_d=NULL;
	double *bcf_d=NULL;
	double *bce_d=NULL;

	cudaMalloc(&f_d, sizeof(double)*sz);

	if ( xbc == 3 || xbc == 4 )
		cudaMalloc(&bcl_d, sizeof(double)*(ny+1)*(nz+1));
	if ( xbc == 3 || xbc == 2 )
		cudaMalloc(&bcr_d, sizeof(double)*(ny+1)*(nz+1));
	if ( ybc == 3 || ybc == 4 )
		cudaMalloc(&bcb_d, sizeof(double)*(nx+1)*(nz+1));
	if ( ybc == 3 || ybc == 2 )
		cudaMalloc(&bct_d, sizeof(double)*(nx+1)*(nz+1));
	if ( zbc == 3 || zbc == 4 )
		cudaMalloc(&bcf_d, sizeof(double)*(nx+1)*(ny+1));
	if ( zbc == 3 || zbc == 2 )
		cudaMalloc(&bce_d, sizeof(double)*(nx+1)*(ny+1));

	cudaMemcpy(f_d, f, sizeof(double)*sz, cudaMemcpyHostToDevice);

	if ( xbc == 3 || xbc == 4 )
		cudaMemcpy(bcl_d, bcl, sizeof(double)*(ny+1)*(nz+1), cudaMemcpyHostToDevice);
	if ( xbc == 3 || xbc == 2 )
		cudaMemcpy(bcr_d, bcr, sizeof(double)*(ny+1)*(nz+1), cudaMemcpyHostToDevice);
	if ( ybc == 3 || ybc == 4 )
		cudaMemcpy(bcb_d, bcb, sizeof(double)*(nx+1)*(nz+1), cudaMemcpyHostToDevice);
	if ( ybc == 3 || ybc == 2 )
		cudaMemcpy(bct_d, bct, sizeof(double)*(nx+1)*(nz+1), cudaMemcpyHostToDevice);
	if ( zbc == 3 || zbc == 4 )
		cudaMemcpy(bcf_d, bcf, sizeof(double)*(nx+1)*(ny+1), cudaMemcpyHostToDevice);
	if ( zbc == 3 || zbc == 2 )
		cudaMemcpy(bce_d, bce, sizeof(double)*(nx+1)*(ny+1), cudaMemcpyHostToDevice);

	//warm up
	cuda_helmholtz_solver(0, 1, nx, xbc, bcl_d, bcr_d, 
			  0, 1, ny, ybc, bcb_d, bct_d,  
			  0, 1, nz, zbc, bcf_d, bce_d, 
			  -1, f_d);

	cudaMemcpy(f_d, f, sizeof(double)*sz, cudaMemcpyHostToDevice);
	time_(
	cuda_helmholtz_solver(0, 1, nx, xbc, bcl_d, bcr_d, 
			  0, 1, ny, ybc, bcb_d, bct_d,  
			  0, 1, nz, zbc, bcf_d, bce_d, 
			  -1, f_d);
	)

	cudaMemcpy(f, f_d, sizeof(double)*sz, cudaMemcpyDeviceToHost);
	cudaFree(f_d);
	if ( xbc == 3 || xbc == 4 )
		cudaFree(bcl_d);
	if ( xbc == 3 || xbc == 2 )
		cudaFree(bcr_d);
	if ( ybc == 3 || ybc == 4 )
		cudaFree(bcb_d);
	if ( ybc == 3 || ybc == 2 )
		cudaFree(bct_d);
	if ( zbc == 3 || zbc == 4 )
		cudaFree(bcf_d);
	if ( zbc == 3 || zbc == 2 )
		cudaFree(bce_d);

//	printf("***********************************\n");

	double maxim = 0;
	for (k=0; k<=nz; k++)
	{
		for (j=0; j<=ny; j++)
		{
			for (i=0; i<=nx; i++)
			{
				//double dif = f[k*(nx+1)*(ny+1)+j*(nx+1)+i] - 1./3*cos(2*PI*i*dx) *cos(2*PI*j*dy)*cos(2*PI*k*dz);
				double dif = f[k*(nx+1)*(ny+1)+j*(nx+1)+i] - 1./3*sin(2*PI*i*dx) *sin(2*PI*j*dy)*sin(2*PI*k*dz);
				//- (k*dz*k*dz + j*dy*j*dy  + i*dx*i*dx);
#ifdef DEBUG
				printf("%12.8f", dif);
#endif
				dif = fabs(dif);
				if (maxim < dif)
					maxim = dif;
//				printf("%.14f\t", f[k*(nx+1)*(ny+1)+j*(nx+1)+i]);// -sin(2*PI*i*dx)*sin(2*PI*j*dy)*sin(2*PI*k*dz));
						//- (k*dz*k*dz + j*dy*j*dy  + i*dx*i*dx));
				//printf("%.14f\t", (f[i+1]-f[i-1])/2./dx);
#ifdef DEBUG
				if (i%9 == 8)
					printf("\n");
#endif
			}
			//printf("\n");
		}
#ifdef DEBUG
		printf("\n");
#endif
	}

	printf("max diff : %.14f\n", maxim);

	delete [] f;
	if ( xbc == 3 || xbc == 4 )
		free(bcl);
	if ( xbc == 3 || xbc == 2 )
		free(bcr);
	if ( ybc == 3 || ybc == 4 )
		free(bcb);
	if ( ybc == 3 || ybc == 2 )
		free(bct);
	if ( zbc == 3 || zbc == 4 )
		free(bcf);
	if ( zbc == 3 || zbc == 2 )
		free(bce);

	return 0;
}
