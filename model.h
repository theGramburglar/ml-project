// abstract class that outlines the functionality of a model.
// for example, we might use the linear least sqaures model for linear regression 
// or a binary logistic model to do binary clasification

#include "kernel.h"

class model{ 
	private:
		bool _parametric;
	public:
		// used to determine how SGD calculates the next value
		model();
		model(bool parametric);
		bool parametric();
		virtual VectorXd gradient(VectorXd w, MatrixXd X, VectorXd y);
		virtual double loss(VectorXd w, MatrixXd X, VectorXd y);
};

class linear_least_squares_model : public model{
	public:
		linear_least_squares_model();
		VectorXd gradient(VectorXd w, MatrixXd  X, VectorXd y);
		double loss(VectorXd w, MatrixXd X, VectorXd y);
};

class binary_logistic_regression_model : public model{
	public:
		binary_logistic_regression_model();
		VectorXd gradient(VectorXd w, MatrixXd  X, VectorXd y);
		double loss(VectorXd w, MatrixXd X, VectorXd y);
};

class kernel_binary_logistic_regression_model: public model{
	protected:
		double _lambda;
		kernel* _k;
		MatrixXd _KXX;
		bool first;
	public:
		kernel_binary_logistic_regression_model();
		kernel_binary_logistic_regression_model(kernel* k, double lambda);
		VectorXd gradient(VectorXd w, MatrixXd  X, VectorXd y);
		double loss(VectorXd w, MatrixXd X, VectorXd y);		
};

class stochstic_kernel_logistic_regression_model: public kernel_binary_logistic_regression_model{
	private:
		VectorXd _dictionary;
		double f(VectorXd w, VectorXd X);
	public:
		stochstic_kernel_logistic_regression_model();
		stochstic_kernel_logistic_regression_model(kernel* k, double lambda);
		VectorXd gradient(VectorXd w, VectorXd X, VectorXd y);
		double loss(VectorXd w, MatrixXd X, VectorXd y);	
};