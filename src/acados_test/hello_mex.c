/* Trivial MEX file: returns 2*x. Used to test "MEX in general" separately from acados. */
#include "mex.h"

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    double x;
    if (nrhs != 1 || !mxIsDouble(prhs[0]))
        mexErrMsgIdAndTxt("hello_mex:args", "one double input required");
    x = mxGetScalar(prhs[0]);
    mexPrintf("hello from MEX\n");
    plhs[0] = mxCreateDoubleScalar(2.0 * x);
}
