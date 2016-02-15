#include <stdio.h>
#include <cuda_runtime.h>
#include <time.h>
#include <curand.h>
#include <random>
#include <iostream>
#include <fstream>
#include <math.h>
#include <sstream>

using namespace std;

__global__ void vStep(float *v, const float *a, float *rand, int numElements) {
	int i = blockDim.x * blockIdx.x + threadIdx.x;
	if (i < numElements)
		rand[i] < 0.5 ? v[i] = v[i] + a[i] : v[i] = -v[i] + a[i];
}

__global__ void pStep(float *pos, const float *v, float *totalDistance,
		int numElements) {
	int i = blockDim.x * blockIdx.x + threadIdx.x;
	if (i < numElements) {
		pos[i] = pos[i] + v[i];
		totalDistance[i] = totalDistance[i] + abs(v[i]);
	}
}

void getRandomVector(float *vector, int n, int i) {
	curandGenerator_t gen;
	curandCreateGenerator(&gen, CURAND_RNG_PSEUDO_DEFAULT);
	curandSetPseudoRandomGeneratorSeed(gen, i * 12);
	curandGenerateUniform(gen, vector, n);
	curandDestroyGenerator(gen);

}

void pStepCpu(float *pos, const float *v, float *totalDistance,
		int numElements) {
	for (int i = 0; i < numElements; i++) {
		pos[i] = pos[i] + v[i];
		totalDistance[i] = totalDistance[i] + abs(v[i]);
	}
}

void vStepCpu(float *v, const float *a, int numElements) {
	for (int i = 0; i < numElements; i++) {
		rand() < 0.5 ? v[i] = v[i] + a[i] : v[i] = -v[i] + a[i];
	}
}

int main(void) {
	srand(time(NULL));
	ofstream myfile;
	int NUMBER_OF_ELEMENTS = 100;
	int ITERATIONS = 100;

	int THEARDS_PER_BLOCK = 257;
	int BLOCKS_PER_GRID = (NUMBER_OF_ELEMENTS + THEARDS_PER_BLOCK - 1)
			/ THEARDS_PER_BLOCK;

	std::stringstream sstm;
	sstm << "simulation_it_" << ITERATIONS << "_NOE_" << NUMBER_OF_ELEMENTS;
	string name = sstm.str();
	myfile.open(name);

	cudaEvent_t start_alloc, stop_alloc, start_computing_GPU,
			stop_computing_GPU, start_computing_CPU, stop_computing_CPU,
			start_copyback, stop_copyback;

	cudaEventCreate(&start_alloc);
	cudaEventCreate(&stop_alloc);
	cudaEventCreate(&start_computing_GPU);
	cudaEventCreate(&stop_computing_GPU);
	cudaEventCreate(&start_computing_CPU);
	cudaEventCreate(&stop_computing_CPU);
	cudaEventCreate(&start_copyback);
	cudaEventCreate(&stop_copyback);

	size_t size = NUMBER_OF_ELEMENTS * sizeof(float);
	float milliseconds;

	float *posX = (float *) malloc(size), *posY = (float *) malloc(size), *vY =
			(float *) malloc(size), *vX = (float *) malloc(size), *aX =
			(float *) malloc(size), *aY = (float *) malloc(size),
			*totalDistanceX = (float *) malloc(size), *totalDistanceY =
					(float *) malloc(size);

	// initial values of velocity vector
	default_random_engine generator;
	normal_distribution<double> distribution(1, 2.5);

	for (int i = 0; i < NUMBER_OF_ELEMENTS; i++) {
		vX[i] = distribution(generator);
		vY[i] = distribution(generator);
	}

	// initial values of acceleration vector
	for (int i = 0; i < NUMBER_OF_ELEMENTS; i++) {
		double lenght = sqrt(vX[i] * vX[i] + vY[i] * vY[i]);
		aX[i] = (vX[i] / lenght) * 0.025;
		aY[i] = (vY[i] / lenght) * 0.025;
	}

	// initial values of position vector also setting the total distance as zero
	for (int i = 0; i < NUMBER_OF_ELEMENTS; i++) {
		posX[i] = 0;
		posY[i] = 0;
		totalDistanceY[i] = 0;
		totalDistanceX[i] = 0;
	}

	// allocating memory on device
	cudaEventRecord(start_alloc);
	float *posXd = NULL, *posYd = NULL, *vYd = NULL, *vXd = NULL, *aXd = NULL,
			*aYd = NULL, *randomd = NULL, *totalDistanceXd = NULL,
			*totalDistanceYd = NULL;

	cudaMalloc((void **) &posXd, size);
	cudaMalloc((void **) &posYd, size);
	cudaMalloc((void **) &vYd, size);
	cudaMalloc((void **) &vXd, size);
	cudaMalloc((void **) &aXd, size);
	cudaMalloc((void **) &aYd, size);
	cudaMalloc((void **) &randomd, size);
	cudaMalloc((void **) &totalDistanceXd, size);
	cudaMalloc((void **) &totalDistanceYd, size);

	// copying the initial values on device
	cudaMemcpy(posXd, posX, size, cudaMemcpyHostToDevice);
	cudaMemcpy(posYd, posY, size, cudaMemcpyHostToDevice);
	cudaMemcpy(vYd, vY, size, cudaMemcpyHostToDevice);
	cudaMemcpy(vXd, vX, size, cudaMemcpyHostToDevice);
	cudaMemcpy(aXd, aX, size, cudaMemcpyHostToDevice);
	cudaMemcpy(aYd, aY, size, cudaMemcpyHostToDevice);
	cudaMemcpy(totalDistanceXd, totalDistanceX, size, cudaMemcpyHostToDevice);
	cudaMemcpy(totalDistanceYd, totalDistanceY, size, cudaMemcpyHostToDevice);

	cudaEventRecord(stop_alloc);
	cudaEventSynchronize(stop_alloc);
	milliseconds = 0;
	cudaEventElapsedTime(&milliseconds, start_alloc, stop_alloc);
	myfile
			<< "% ---------------------------------------------------------- %\n";
	myfile << "allocation_time = " << milliseconds << ";\n";

	// simulation CPU
	cudaEventRecord(start_computing_CPU);
	for (int i = 0; i < ITERATIONS; i++) {
		vStepCpu(vX, aX, NUMBER_OF_ELEMENTS);
		vStepCpu(vY, aY, NUMBER_OF_ELEMENTS);
		pStepCpu(vX, aX, totalDistanceX, NUMBER_OF_ELEMENTS);
		pStepCpu(vY, aY, totalDistanceY, NUMBER_OF_ELEMENTS);
	}
	cudaEventRecord(stop_computing_CPU);
	cudaEventSynchronize(stop_computing_CPU);
	milliseconds = 0;
	cudaEventElapsedTime(&milliseconds, start_computing_CPU,
			stop_computing_CPU);

	// all that matters to me is execution time
	myfile << "cpu_compution_time = " << milliseconds << ";\n";

	// simulation GPU
	cudaEventRecord(start_computing_GPU);
	for (int i = 1; i < ITERATIONS; i++) {
		getRandomVector(randomd, NUMBER_OF_ELEMENTS, i);
		vStep<<<BLOCKS_PER_GRID, THEARDS_PER_BLOCK>>>(vXd, aXd, randomd, NUMBER_OF_ELEMENTS);
		vStep<<<BLOCKS_PER_GRID, THEARDS_PER_BLOCK>>>(vYd, aYd, randomd, NUMBER_OF_ELEMENTS);
		pStep<<<BLOCKS_PER_GRID, THEARDS_PER_BLOCK>>>(posXd,vXd,totalDistanceXd, NUMBER_OF_ELEMENTS);
		pStep<<<BLOCKS_PER_GRID, THEARDS_PER_BLOCK>>>(posYd,vYd,totalDistanceYd, NUMBER_OF_ELEMENTS);
	}

	cudaEventRecord(stop_computing_GPU);
	cudaEventSynchronize(stop_computing_GPU);
	milliseconds = 0;
	cudaEventElapsedTime(&milliseconds, start_computing_GPU,
			stop_computing_GPU);

	myfile << "gpu_compution_time = " << milliseconds << ";\n";

	// getting the results back to host
	cudaEventRecord(start_copyback);
	cudaMemcpy(posX, posXd, size, cudaMemcpyDeviceToHost);
	cudaMemcpy(posY, posYd, size, cudaMemcpyDeviceToHost);
	cudaMemcpy(totalDistanceX, totalDistanceXd, size, cudaMemcpyDeviceToHost);
	cudaMemcpy(totalDistanceY, totalDistanceYd, size, cudaMemcpyDeviceToHost);

	cudaEventRecord(stop_copyback);
	cudaEventSynchronize(stop_copyback);
	milliseconds = 0;
	cudaEventElapsedTime(&milliseconds, stop_copyback, stop_copyback);

	myfile << "copyback_time = " << milliseconds << ";\n";

	// print section
	myfile
			<< "% ---------------------------------------------------------- %\n";
	myfile << "number_of_particles = " << NUMBER_OF_ELEMENTS << ";\n";
	myfile << "number_of_iterations = " << ITERATIONS << ";\n";
	myfile
			<< "% ---------------------------------------------------------- %\n";

	myfile << "displacement = [";
	for (int i = 0; i < NUMBER_OF_ELEMENTS - 1; i++) {
		myfile << sqrt(posX[i] * posX[i] + posY[i] * posY[i]) << ", ";
	}
	myfile
			<< sqrt(
					posX[NUMBER_OF_ELEMENTS - 1] * posX[NUMBER_OF_ELEMENTS - 1]
							+ posY[NUMBER_OF_ELEMENTS - 1]
									* posY[NUMBER_OF_ELEMENTS - 1]) << "];\n";

	myfile << "final_positions = [";
	for (int i = 0; i < NUMBER_OF_ELEMENTS - 1; i++) {
		myfile << "[" << posX[i] << ", " << posY[i] << "], ";
	}
	myfile << "[" << posX[NUMBER_OF_ELEMENTS - 1] << ", "
			<< posY[NUMBER_OF_ELEMENTS - 1] << "]];\n";

	myfile << "total_distances = [";
	for (int i = 0; i < NUMBER_OF_ELEMENTS - 1; i++) {
		myfile << sqrt(totalDistanceX[i] + totalDistanceY[i]) << ", ";
	}
	myfile
			<< sqrt(
					totalDistanceX[NUMBER_OF_ELEMENTS - 1]
							+ totalDistanceY[NUMBER_OF_ELEMENTS - 1]) << "];\n";

	myfile << "final_velocities = [";
	for (int i = 0; i < NUMBER_OF_ELEMENTS - 1; i++) {
		myfile << sqrt(vX[i] * vX[i] + vY[i] * vY[i]) << ", ";
	}
	myfile
			<< sqrt(
					vX[NUMBER_OF_ELEMENTS - 1] * vX[NUMBER_OF_ELEMENTS - 1]
							+ vY[NUMBER_OF_ELEMENTS - 1]
									* vY[NUMBER_OF_ELEMENTS - 1]) << "];\n";

	myfile.close();

	// free the allocated memory
	free(posX);
	free(posY);
	free(vY);
	free(vX);
	free(aX);
	free(aY);
	free(totalDistanceX);
	free(totalDistanceY);

	cudaFree(posXd);
	cudaFree(posYd);
	cudaFree(vYd);
	cudaFree(vXd);
	cudaFree(aXd);
	cudaFree(aYd);
	cudaFree(totalDistanceXd);
	cudaFree(totalDistanceYd);

	return 0;
}

