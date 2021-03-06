from eigency.core cimport * 
from libcpp.vector cimport vector
from decl cimport kernel as _kernel
from decl cimport linear_kernel as _linear_kernel
from decl cimport polynomial_kernel as _polynomial_kernel
from decl cimport gaussian_kernel as _gaussian_kernel
from decl cimport model as _model
from decl cimport linear_least_squares_model as _lls_model
from decl cimport binary_logistic_regression_model as _blr_model
from decl cimport kernel_binary_logistic_regression_model as _kblr_model
from decl cimport stochastic_kernel_logistic_regression_model as _sklr_model
from decl cimport optomization_solver_base as _solver_base
from decl cimport batch_gradient_descent as _BGD
from decl cimport stochastic_gradient_descent as _SGD
import numpy as np

def col_major(n):
	"""convert the array to column-major to pass to Eigen"""
	# if the shape of n is (len(n),) then it is treated as having len(n) samples with 1 feature so we'll adjust the shape
	if len(n.shape) == 1:
		n.shape = len(n),1
		return np.array(n,order='F')
	return np.array(n.transpose(),order='F')
	 

cdef class kernel:
	"""Abstract Class that serves as a base for kernels and provides an implementation of gram_matrix()"""
	cdef _kernel* thisptr;

	def __cinit__(self):
		thisptr = NULL

	def __dealloc__(self):
		pass

	def gram_matrix(self, np.ndarray X, np.ndarray Y):
		"""computes the gram_matrix for two arrays X and Y
		Parameters:
			X is a Mxd matrix with M samples and d features
			Y is a Nxd matrix with N samples and d features
 		Returns:
 			K - where the [i,j] entry of K is k(x_i,y_j) and x_i, y_j are the ith and jth samples of X and Y.
		"""
		if self.thisptr is NULL:
			raise Exception("Cannot call gram_matrix() on kernel base class!")
		else:
			_x = col_major(X)
			_y = col_major(Y)
			return ndarray_copy(self.thisptr.gram_matrix(Map[MatrixXd](_x), Map[MatrixXd](_y)))

cdef class linear_kernel(kernel):
	"""linear kernel, impl based on:
	http://crsouza.com/2010/03/17/kernel-functions-for-machine-learning-applications/#linear
	"""
	
	def __cinit__(self, double c):
		self.thisptr = new _linear_kernel(c)

	def __dealloc__(self):
		del self.thisptr

cdef class polynomial_kernel(kernel):
	"""polynomial kernel, impl based on:
	http://crsouza.com/2010/03/17/kernel-functions-for-machine-learning-applications/#polynomial
	"""

	def __cinit__(self, double a, double c, double d):
		self.thisptr = new _polynomial_kernel(a, c, d)

	def __dealloc__(self):
		del self.thisptr

cdef class gaussian_kernel(kernel):
	"""gaussian kernel, impl based on:
	http://crsouza.com/2010/03/17/kernel-functions-for-machine-learning-applications/#gaussian
	"""
	
	def __cinit__(self, double s):
		self.thisptr = new _gaussian_kernel(s)

	def __dealloc__(self):
		del self.thisptr

cdef class model:
	"""Abstract Base class for models"""
	cdef _model* thisptr

	def __cinit__(self):
		thisptr = NULL

	def __dealloc__(self):
		pass

	def loss(self, np.ndarray X, np.ndarray y):
		""""""
		if self.thisptr is NULL:
			raise Exception("Cannot call loss() on model base class!")
		else:
			_x = col_major(X)
			_y = col_major(y)
			return self.thisptr.loss(Map[MatrixXd](_x), Map[VectorXd](_y))

	def predict(self, np.ndarray X):
		"""takes a feature vector X and returns P(label=1|X)"""
		if self.thisptr is NULL:
			raise Exception("Cannot call predict() on model base class!")
		else:
			_x = col_major(X)
			return ndarray_copy(self.thisptr.predict(Map[MatrixXd](_x)))

	def get_weights(self):
		"""returns the current value of the weights on this model"""
		if self.thisptr is NULL:
			raise Exception("Cannot call get_weights() on model base class!")
		else:
			return ndarray_copy(self.thisptr.get_weights())

cdef class lls_model(model):
	'''Linear Least Squares Model'''
	def __cinit__(self):
		self.thisptr = new _lls_model()

	def __dealloc__(self):
		del self.thisptr

cdef class blr_model(model):
	'''Binary Logistic Regression Model'''
	def __cinit__(self):
		self.thisptr = new _blr_model()

	def __dealloc__(self):
		del self.thisptr

cdef class kblr_model(model):
	'''Kernel Binary Logistic Regression Model'''

	cdef kernel _k 

	def __cinit__(self, kernel k, double l):
		self._k = k
		self.thisptr = new _kblr_model(k.thisptr, l)

	def __dealloc__(self):
		del self.thisptr

cdef class sklr_model(model):
	'''Stochastic Kernel Binary Logistic Regression Model'''

	cdef _sklr_model* sklr_ptr
	cdef kernel _k 

	def __cinit__(self, kernel k, double l, double err_max):
		self._k = k
		self.thisptr = self.sklr_ptr = new _sklr_model(k.thisptr, l, err_max)

	def __dealloc__(self):
		del self.thisptr

	def dictionary(self):
		return ndarray_copy(self.sklr_ptr.dictionary()).transpose()

cdef class solver:
	"""Abstract base class for solvers"""
	cdef _solver_base* thisptr

	def __cinit__(self):
		thisptr = NULL

	def __dealloc__(self):
		pass

	def get_loss_values(self):
		if self.thisptr is NULL:
			raise Exception("Cannot call get_loss_values on solver base class!")
		else:
			return np.array(list(self.thisptr.get_loss_values()))

cdef class BGD(solver):
	'''Batch Gradient Descent Solver'''
	cdef _BGD* bgdptr

	def __cinit__(self, np.ndarray x, np.ndarray y, model m not None):
		cdef _model* mod = m.thisptr
		_x = col_major(x)
		_y = col_major(y)
		self.thisptr = self.bgdptr = new _BGD(Map[MatrixXd](_x), Map[VectorXd](_y), mod)

	def __dealloc__(self):
		del self.thisptr
		
	def fit(self, double step_size, str conv_type, double conv_val):
		"""runs the batch gradient descent algorithm to optimize the weights on the given model
		Prameters:
			step_size - the step size used to scale the gradient when updating the weights
			conv_type - determines when to terminate training valid values include:
				'step_precision' - terminate when the difference between the weights after a single step is less than a threshold
				'loss_precision' - terminate when the change in loss after a single step is less than a threshold
				'iterations' - take a given number of gradient steps
			conv_val - the number that corresponds to the conv_type described above
		"""
		# call encode on conv_type b/c Cython is expecting a byte type string and Python 3 string literals are type str
		self.bgdptr.fit(step_size, conv_type.encode(), conv_val)

cdef class SGD(solver):
	'''Stochastic Gradient Descent Solver'''
	cdef _SGD* sgdptr

	def __cinit__(self, model m not None):
		cdef _model* mod = m.thisptr
		self.thisptr = self.sgdptr = new _SGD(mod)

	def __dealloc__(self):
		del self.thisptr

	def fit(self, double step_size, np.ndarray data, np.ndarray labels):
		"""updates the weights on the model by taking a single gradient step
		Parameters:
			step_size - the step size used to scale the gradient when updating the weights
			data - a Nxd matrix of observations. data contains N samples with d dimensions
			labels - a N-length vector of labels for the given data
		"""
		_data = col_major(data)
		_labels = col_major(labels)
		self.sgdptr.fit(step_size, Map[MatrixXd](_data), Map[VectorXd](_labels))