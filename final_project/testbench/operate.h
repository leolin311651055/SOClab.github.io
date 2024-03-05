#ifndef _OPERATE_H
#define _OPERATE_H

#define SIZE 4
#define SIZE_QS 10
	// matrix multiplication
	int A[SIZE*SIZE] = {
			0, 1, 2, 3,
			0, 1, 2, 3,
			0, 1, 2, 3,
			0, 1, 2, 3
	};
	int B[SIZE*SIZE] = {
		1, 2, 3, 4,
		5, 6, 7, 8,
		9, 10, 11, 12,
		13, 14, 15, 16
	};
	int result[SIZE*SIZE];
	
	// quick sort
	int QS[SIZE_QS] = {893, 40, 3233, 4267, 2669, 2541, 9073, 6023, 5681, 4622};

	// fir

	int ans[64];
	int inputdata[64] = {
		0, 1, 2, 3, 4, 5, 6, 7,
		8, 9, 10, 11, 12, 13, 14, 15,
		16, 17, 18, 19, 20, 21, 22, 23,
		24, 25, 26, 27, 28, 29, 30, 31,
		32, 33, 34, 35, 36, 37, 38, 39,
		40, 41, 42, 43, 44, 45, 46, 47,
		48, 49, 50, 51, 52, 53, 54, 55,
		56, 57, 58, 59, 60, 61, 62, 63
	};
	
#endif
