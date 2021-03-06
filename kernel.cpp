/* implementation of various kernels and the gram_matrix method in the parnet kernel class  */

#include "kernel.h"

/*
 Implementation for the gram_matrix method that all children of kernel use
 It is dependent on the virtual method k() which computes the kernel between two vectors 
*/

/* 
 * X is a dxM matrix and Y is a dxN matrix
 * this function computes the Gram Matrix/Kernel Matrix K(X,Y) where the (i,j) entry of K
 * is k(x_i,y_j) and x_i, y_j are the ith and jth columns of X and Y. 
 */
MatrixXd kernel::gram_matrix(Map<MatrixXd> &X, Map<MatrixXd> &Y){
	return gram_matrix(MatrixXd(X),MatrixXd(Y));
}

MatrixXd kernel::gram_matrix(const MatrixXd &X, const MatrixXd &Y){
	if(X.rows() != Y.rows()){
		throw invalid_argument("to compute a Gram Matrix both input matrices must have the same number of rows.");
	}
	// cout << "X:\n" << X << endl;
	// cout << "Y:\n" << Y << endl;
	int M = X.cols();
	int N = Y.cols();
	MatrixXd result = MatrixXd(M,N);
	for(int i = 0; i < M; ++i){
		for(int j = 0; j < N; ++j){
			result(i,j) = this->k(X.col(i),Y.col(j));
		}
	}
	return result;
}

MatrixXd kernel::gram_matrix_stable(Map<MatrixXd> &X, Map<MatrixXd> &Y){
	return gram_matrix_stable(MatrixXd(X),MatrixXd(Y));
}

MatrixXd kernel::gram_matrix_stable(const MatrixXd &X, const MatrixXd &Y){
	// this value is necessary to avoid getting inf and nan when inverting a gram_matrix where x and y share values
	double stability = 1e-3;
	MatrixXd result = gram_matrix(X, Y);
	// if the result is a 1x1 matrix
	if(result.size() == 1 && result(0, 0) == 1){
		// cout << "1x1\n";
		result(0, 0) = result(0, 0) + stability;
		return result;
	}
	// the result is NXM where N > 1 and M > 1
	else if(result.rows() > 1 && result.cols() > 1){
		// cout << "normal\n";
		return result + (stability * MatrixXd::Identity(X.cols(), Y.cols()));
	}
	// if the result is a column matrix
	else if((result.cols() == 1 || result.rows() == 1) && result(result.size()-1) == 1){
		// cout << "column/row\n";
		result(result.size() - 1) += stability;
		return result;
	}
	else{
		return result;
	}
}

/* Implementation for the linear_kernel class */

linear_kernel::linear_kernel(double c):
	_c(c)
	{}

// http://crsouza.com/2010/03/17/kernel-functions-for-machine-learning-applications/#linear
double linear_kernel::k(VectorXd x_i, VectorXd y_j){
	return x_i.transpose() * y_j + _c;
}

/* Implementation for the polynomial_kernel class */

polynomial_kernel::polynomial_kernel(double a, double c, double d):
	_a(a),
	_c(c),
	_d(d)
	{}

//http://crsouza.com/2010/03/17/kernel-functions-for-machine-learning-applications/#polynomial
double polynomial_kernel::k(VectorXd x_i, VectorXd y_j){
	double dot = x_i.transpose() * y_j;
	double base = _a * dot + _c;
	return pow(base,_d);
}

/* Implementation for the gaussian_kernel class */

gaussian_kernel::gaussian_kernel(double s):
	_s(s)
	{}

// http://crsouza.com/2010/03/17/kernel-functions-for-machine-learning-applications/#gaussian
double gaussian_kernel::k(VectorXd x_i, VectorXd y_j){
	// cout << "WHY\n";
	return exp(-1 * (x_i - y_j).array().square().sum() / (2 * _s * _s));
}