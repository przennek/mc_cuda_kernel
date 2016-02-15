#include <iostream>
#include <stdio.h>
#include <cuda_runtime.h>
#include <time.h>
#include <iostream>
#include <math.h>

using namespace std;

__global__ void
velStepRand(float *v, const float *a, float *rand, int numElements)
{
	 int i = blockDim.x * blockIdx.x + threadIdx.x;
	 if(i < numElements){

		 if (rand[i]<0.5)
		 {
			 v[i] = v[i] + a[i];

		 }
		 else{
			 v[i] = -v[i] + a[i];

		 }

	 }

}




int main(void) {
	cout << "aa";
	return 0;
}

