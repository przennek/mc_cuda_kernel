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

float isKTheLowestNumInArr(thrust::device_vector<float> first, float kTheLowest,int k) {
	for(int i =0; i<k; i++){
		//cout << kTheLowest << " " <<first[i]<<endl;
		if (kTheLowest == first[i])
		   return 1;
		if(kTheLowest > first[i])
			return 0;
	}
	return 0;
}


int main(void) {
	const int nFPoints = 1000000;
	const int size = nFPoints;
	const float k = 5;

	float tDivider = (2000*(k-1));
	cout << (tDivider) << endl;
	float mean = 0.49974;
	float var = sqrt(0.0006);

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
	thrust::device_vector<float> htd = ht;

	int threadsPerBlock = 257;
	int blocksPerGrid = (1000 + threadsPerBlock - 1) / threadsPerBlock;

	float t = 0;

	 for(int j = 0; j< 1000; j ++){
	 for(int i=0; i < 1000; i++) {
	    countDis<<<blocksPerGrid, threadsPerBlock>>>(x1[i+(j*1000)],y1[i+(j*1000)], thrust::raw_pointer_cast(&x1d[j*1000]), thrust::raw_pointer_cast(&y1d[j*1000]), thrust::raw_pointer_cast(&disIn[0]),1000);
	    countDis<<<blocksPerGrid, threadsPerBlock>>>(x1[i+(j*1000)],y1[i+(j*1000)], thrust::raw_pointer_cast(&x2d[j*1000]), thrust::raw_pointer_cast(&y2d[j*1000]), thrust::raw_pointer_cast(&disOut[0]),1000);
	    thrust::device_vector<float> disBoth = disIn;
	    disBoth.insert(disBoth.end(), disOut.begin(), disOut.end());

	    thrust::sort(disBoth.begin(),disBoth.end());
	    thrust::sort(disOut.begin(), disOut.end());
	    // thrust::host_vector<float> both = disBoth;
	    // thrust::host_vector<float> in = disIn;

	    for(int i = 0; i < k; i++) {
	    	 t += isKTheLowestNumInArr(disOut, disBoth[i],k);
	    }
	   // cout << i << endl;
	 }



	 for(int i=0; i < 1000; i++){
		 countDis<<<blocksPerGrid, threadsPerBlock>>>(x2[i+(j*1000)],y2[i+(j*1000)], thrust::raw_pointer_cast(&x1d[j*1000]), thrust::raw_pointer_cast(&y1d[j*1000]), thrust::raw_pointer_cast(&disOut[0]),1000);
		 countDis<<<blocksPerGrid, threadsPerBlock>>>(x2[i+(j*1000)],y2[i+(j*1000)], thrust::raw_pointer_cast(&x2d[j*1000]), thrust::raw_pointer_cast(&y2d[j*1000]), thrust::raw_pointer_cast(&disIn[0]),1000);
		 thrust::device_vector<float> disBoth = disIn;
		 disBoth.insert(disBoth.end(), disOut.begin(), disOut.end());

		 thrust::sort(disBoth.begin(),disBoth.end());
		 thrust::sort(disOut.begin(), disOut.end());
		 	// thrust::host_vector<float> both = disBoth;
		 	// thrust::host_vector<float> in = disIn;

		 for(int i = 1; i < k; i++) {
		 	t += isKTheLowestNumInArr(disOut, disBoth[i],k);
		 }
		 //cout << i << endl;
	 }


	 cout << ((t/tDivider) -mean)*var << endl;
	// cout << t << endl;
	 t = 0;
   }
	cout << "Koniec.";
	cudaDeviceReset();
	return 0;
}
