#include <iostream>
#include <fstream>
#include <stdio.h>
#include <cuda_runtime.h>
#include <time.h>
#include <iostream>
#include <math.h>
#include <vector>

using namespace std;

const int LINE_LEN = 4003;


__global__ void
countDis(float x, float y, float *x1, float *y1, float * result,  int numElements)
{
    int i = blockDim.x * blockIdx.x + threadIdx.x;

    if (i < numElements)
    {
        result[i] = sqrt((x-x1[i])*(x-x1[i]) + (y-y1[i])*(y-y1[i]));

    }
}

__device__ void
countAllDistArr(float *x1, float *y1,float *x2, float *y2, float * result, int size){

	int i = blockDim.x * blockIdx.x + threadIdx.x;

	 if (i < size*size)
	    {
	       // countDis(x1[i], y1[i], x2,y2, result + i*size,size);
	    }

}



int main(void) {
	const int nFPoints = 1000000;
	const int size = nFPoints;
	float * x1 = (float*)malloc(nFPoints * sizeof(float));
	float * y1 = (float*)malloc(nFPoints * sizeof(float));
	float * x2 = (float*)malloc(nFPoints * sizeof(float));
	float * y2 = (float*)malloc(nFPoints * sizeof(float));

	string line;

	std::fstream myfile("/home/gr/Pulpit/multicorev2/mc_fit/src/Gauss_1111.txt", std::ios_base::in);

	    float a;

	 for(int i =0; i < size; i++){
	    	myfile >> a;
	    	x1[i] = a;
	    	myfile >> a;
	        y1[i] = a;
	        myfile >> a;
	        x2[i] = a;
	    	myfile >> a;
	        y2[i] = a;
	 }



	 float *x1d = NULL;
	 cudaMalloc((void **)&x1d, size);

	 float *y1d = NULL;
	 cudaMalloc((void **)&y1d, size);

	 float *x2d = NULL;
	 cudaMalloc((void **)&x2d, size);

	 float *y2d = NULL;
	 cudaMalloc((void **)&y2d, size);

	 float *disIn = NULL;
	 cudaMalloc((void **)&disIn, 1000);
	 float *disOut = NULL;
	 cudaMalloc((void **)&disOut, 1000);
	 float *t = NULL;
	 cudaMalloc((void **)&t, 2000);


	 cudaMemcpy(x1d, x1, size, cudaMemcpyHostToDevice);
	 cudaMemcpy(y1d, y1, size, cudaMemcpyHostToDevice);
	 cudaMemcpy(x2d, x2, size, cudaMemcpyHostToDevice);
	 cudaMemcpy(y2d, y2, size, cudaMemcpyHostToDevice);




	    int threadsPerBlock = 257;
	    int blocksPerGrid =(1000 + threadsPerBlock - 1) / threadsPerBlock;

	 //liczymy pojedyncze T
	    for(int i =0; i < 1000 ; i++){
	    	countDis<<<blocksPerGrid, threadsPerBlock>>>(x1[i],y1[i],x1d,y1d,disIn,1000);
	    	countDis<<<blocksPerGrid, threadsPerBlock>>>(x1[i],y1[i],x2d,y2d,disOut,1000);
	    	//do tablicy t na pozycje i wpisujemy ilosc sposrod k najblizszych dystatnsow z
	    	//disIn, disOut, ktore znajduja sie w disOut
	    	//countSingleT<<<blocksPerGrid, threadsPerBlock>>>(disIn, disOut, t , 1000, i,k);
	    }
	    for(int i =0; i < 1000 ; i++){
	    	countDis<<<blocksPerGrid, threadsPerBlock>>>(x2[i],y2[i],x1d,y1d,disOut,1000);
	        countDis<<<blocksPerGrid, threadsPerBlock>>>(x2[i],y2[i],x2d,y2d,disIn,1000);
	        //do tablicy t na pozycje i + 1000 wpisujemy ilosc sposord k najblizszych dystatnsow z
	        //disIn, disOut, ktore znajduja sie w disOut
	        //countSingleT<<<blocksPerGrid, threadsPerBlock>>>(disIn, disOut, t , 1000, i +1000,k);
	    }
	    //suma tablicy t to pojedyncze T




	free(x1);
	free(y1);
	free(x2);
	free(y2);

	cout << "Koniec.";
	return 0;
}
