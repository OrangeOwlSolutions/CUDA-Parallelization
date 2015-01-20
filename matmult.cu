#include <cblas.h>
#include <cuda_runtime.h>
#include <cublas_v2.h>

void matmult_nat(int m, int n, int k, double *A, double *B, double *C)
{
    int i, j, h;
    for (i = 0; i < m; i++)
    {
        for (j = 0; j < n; j++)
        {
            C[n * i + j] = 0.0;
            for (h = 0; h < k; h++)
            {
                C[n * i + j] += A[k * i + h] * B[n * h + j];
            }
        }
    }
}

void matmult_mnk(int m, int n, int k, double *A, double *B, double *C)
{
    int i, j, h;
    for (i = 0; i < m * n; i++)
    {
        C[i] = 0.0;
    }
    for (i = 0; i < m; i++)
    {
        for (j = 0; j < n; j++)
        {
            for (h = 0; h < k; h++)
            {
                C[n * i + j] += A[k * i + h] * B[n * h + j];
            }
        }
    }
}

void matmult_nmk(int m, int n, int k, double *A, double *B, double *C)
{
    int i, j, h;
    for (i = 0; i < m * n; i++)
    {
        C[i] = 0.0;
    }
    for (j = 0; j < n; j++)
    {
        for (i = 0; i < m; i++)
        {
            for (h = 0; h < k; h++)
            {
                C[n * i + j] += A[k * i + h] * B[n * h + j];
            }
        }
    }
}

void matmult_nkm(int m, int n, int k, double *A, double *B, double *C)
{
    int i, j, h;
    for (i = 0; i < m * n; i++)
    {
        C[i] = 0.0;
    }
    for (j = 0; j < n; j++)
    {
        for (h = 0; h < k; h++)
        {
            for (i = 0; i < m; i++)
            {
                C[n * i + j] += A[k * i + h] * B[n * h + j];
            }
        }
    }
}

void matmult_kmn(int m, int n, int k, double *A, double *B, double *C)
{
    int i, j, h;
    for (i = 0; i < m * n; i++)
    {
        C[i] = 0.0;
    }
    for (h = 0; h < k; h++)
    {
        for (i = 0; i < m; i++)
        {
            for (j = 0; j < n; j++)
            {
                C[n * i + j] += A[k * i + h] * B[n * h + j];
            }
        }
    }
}

void matmult_knm(int m, int n, int k, double *A, double *B, double *C)
{
    int i, j, h;
    for (i = 0; i < m * n; i++)
    {
        C[i] = 0.0;
    }
    for (h = 0; h < k; h++)
    {
        for (j = 0; j < n; j++)
        {
            for (i = 0; i < m; i++)
            {
                C[n * i + j] += A[k * i + h] * B[n * h + j];
            }
        }
    }
}

void matmult_mkn(int m, int n, int k, double *A, double *B, double *C)
{
    int i, j, h;
    for (i = 0; i < m * n; i++)
    {
        C[i] = 0.0;
    }
    for (i = 0; i < m; i++)
    {
        for (h = 0; h < k; h++)
        {
            for (j = 0; j < n; j++)
            {
                C[n * i + j] += A[k * i + h] * B[n * h + j];
            }
        }
    }
}

void matmult_lib(int m, int n, int k, double *A, double *B, double *C)
{
    cblas_dgemm(CblasRowMajor, CblasNoTrans, CblasNoTrans, m, n, k, 1.0, A, k, B, n, 0.0, C, n);
}

__global__ void matmult_gpu1_thread(int m, int n, int k, double *A, double *B, double *C)
{
    int row = blockIdx.y * blockDim.y + threadIdx.y;
    int col = blockIdx.x * blockDim.x + threadIdx.x;
    if (row <= m && col <= n)
    {
        double sum = 0.0;
        for (int h = 0; h < k; h++)
        {
            sum += A[k * row + h] * B[n * h + col]);
        }
        C[n * row + col] = sum;
    }
}

void matmult_gpu1(int m, int n, int k, double *A, double *B, double *C)
{
	double *device_a, *device_b, *device_c;
	cudaMalloc((void**) &device_a, m * k * sizeof(double));
	cudaMalloc((void**) &device_b, k * n * sizeof(double));
	cudaMalloc((void**) &device_c, m * n * sizeof(double));

	cudaMemcpy(device_a, A, m * k * sizeof(double), cudaMemcpyHostToDevice);
	cudaMemcpy(device_b, B, k * n * sizeof(double), cudaMemcpyHostToDevice);

	int block_size = 256;

	dim3 DimGrid(n + block_size - 1) / block_size, (m + block_size - 1) / block_size));
    dim3 DimBlock(block_size, block_size);

    matmult_gpu1_thread <<< DimGrid, DimBlock >>> (m, n, k, device_a, device_b, device_c);

    cudaDeviceSynchronize();

    cudaMemcpy(C, device_c, m * n * sizeof(double), cudaMemcpyDeviceToHost);

    cudaFree(device_a);
    cudaFree(device_b);
    cudaFree(device_c);
}

void matmult_gpu2(int m, int n, int k, double *A, double *B, double *C)
{

}

void matmult_gpu3(int m, int n, int k, double *A, double *B, double *C)
{

}

void matmult_gpu4(int m, int n, int k, double *A, double *B, double *C)
{

}

void matmult_gpu5(int m, int n, int k, double *A, double *B, double *C)
{

}

void matmult_gpulib(int m, int n, int k, double *A, double *B, double *C)
{

}
