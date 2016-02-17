#include <iostream>
#include <fstream>
#include <stdio.h>
#include <cuda_runtime.h>
#include <time.h>
#include <iostream>
#include <math.h>
#include <vector>

#include <thrust/host_vector.h>
#include <thrust/device_vector.h>
#include <thrust/sort.h>

using namespace std;

__global__ void
countDis(float x, float y, float *x1, float *y1, float * result,  int numElements) {
    int i = blockDim.x * blockIdx.x + threadIdx.x;

    if (i < numElements) {
        result[i] = sqrt((x-x1[i])*(x-x1[i]) + (y-y1[i])*(y-y1[i]));

    }
}

int isKTheLowestNumInArr(thrust::host_vector<float> first, float kTheLowest) {
	if(std::find(first.begin(), first.end(), x) != first.end()) {
	    return 1;
	} else {
	    return 0;
	}
}


int main(void) {
	const int nFPoints = 1000000;
	const int size = nFPoints;
	const int k = 5;

	thrust::host_vector<float> x1(nFPoints);
	thrust::host_vector<float> y1(nFPoints);
	thrust::host_vector<float> x2(nFPoints);
	thrust::host_vector<float> y2(nFPoints);

	thrust::host_vector<float> hdisIn(1000);
	thrust::host_vector<float> hdisOut(1000);
	thrust::host_vector<float> ht(nFPoints);

	string line;

	std::fstream myfile("Gauss_1111.txt", std::ios_base::in);

	float a;

	for(int i =0; i < size; i++) {
		myfile >> a;
		x1[i] = a;
		myfile >> a;
		y1[i] = a;
		myfile >> a;
		x2[i] = a;
		myfile >> a;
		y2[i] = a;
	}

	thrust::device_vector<float> x1d = x1;
	thrust::device_vector<float> y1d = y1;
	thrust::device_vector<float> x2d = x2;
	thrust::device_vector<float> y2d = y2;

	thrust::device_vector<float> disIn = hdisIn;
	thrust::device_vector<float> disOut = hdisOut;
	thrust::device_vector<float> t = ht;

	int threadsPerBlock = 257;
	int blocksPerGrid = (1000 + threadsPerBlock - 1) / threadsPerBlock;

	float t = 0;

	 //liczymy pojedyncze T
	 for(int i=0; i < 1000; i++) {
	    countDis<<<blocksPerGrid, threadsPerBlock>>>(x1[i],y1[i], thrust::raw_pointer_cast(&x1d[0]), thrust::raw_pointer_cast(&y1d[0]), thrust::raw_pointer_cast(&disIn[0]),1000);
	    countDis<<<blocksPerGrid, threadsPerBlock>>>(x1[i],y1[i], thrust::raw_pointer_cast(&x2d[0]), thrust::raw_pointer_cast(&y2d[0]), thrust::raw_pointer_cast(&disOut[0]),1000);
	    //do tablicy t na pozycje i wpisujemy ilosc sposrod k najblizszych dystatnsow z
	    //disIn, disOut, ktore znajduja sie w disOut
	    //countSingleT<<<blocksPerGrid, threadsPerBlock>>>(disIn, disOut, t , 1000, i,k);
	 }

	 thrust::device_vector<float> disBoth = disIn;
	 disBoth.insert(disBoth.end(), disOut.begin(), disOut.end());

	 thrust::sort(disBoth.begin(),disBoth.end());
	 thrust::host_vector<float> both = disBoth;
	 thrust::host_vector<float> in = disIn;

	 for(int i = 0; i < k; i++) {
		 t += isKTheLowestNumInArr(in, both[i]);
	 }

	 for(int i=0; i < 1000; i++){
		 countDis<<<blocksPerGrid, threadsPerBlock>>>(x2[i],y2[i], thrust::raw_pointer_cast(&x1d[0]), thrust::raw_pointer_cast(&y1d[0]), thrust::raw_pointer_cast(&disIn[0]),1000);
		 countDis<<<blocksPerGrid, threadsPerBlock>>>(x2[i],y2[i], thrust::raw_pointer_cast(&x2d[0]), thrust::raw_pointer_cast(&y2d[0]), thrust::raw_pointer_cast(&disOut[0]),1000);
	    //do tablicy t na pozycje i + 1000 wpisujemy ilosc sposord k najblizszych dystatnsow z
	    //disIn, disOut, ktore znajduja sie w disOut
	    //countSingleT<<<blocksPerGrid, threadsPerBlock>>>(disIn, disOut, t , 1000, i +1000,k);
	 }
	 //suma tablicy t to pojedyncze T



//	cout << "Koniec.";
	return 0;
}
