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

string* readLine(string line, int lineLen) {
	 string* tokensArr = new string[lineLen];
	 std::vector<std::string> tokens;
	 split(tokens, str, is_any_of(" "));
	 int counter = 0;
	 for(auto& s: tokens) {
		 tokensArr[counter++] = s;
	 }
	 return tokensArr;
}

void appendVec(string* line, int lineLen, vector<float>* data1X, vector<float>* data1Y, vector<float>* data2X, vector<float>* data2Y) {

}

int main(void) {
	const int nFPoints = 1000;
	const int rows = 4;
	float **data = (float**)malloc(rows * sizeof(float*));
	for(int i = 0; i < rows; i++) {
		data[i] = (float*)malloc(nFPoints * sizeof(float));
	}

	string line;
	ifstream myfile("Gauss_1111.txt");
	if (myfile.is_open()) {
		while (getline (myfile, line)) {
//			cout << line << '\n';
	    }
	    myfile.close();
	}
	else cout << "Unable to open file";

	for(int i = 0; i < rows; i++) {
		free(data[i]);
	}
	free(data);

	cout << "Koniec.";
	return 0;
}
