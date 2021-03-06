#include <stdio.h>
#include <helper_cuda.h>
#include <string.h>

#define BLOCK_SIZE 32


void init(int N, double delta, double *U0, double *U_old0, double *U1, double *U_old1, double *F)
{

    int temp_N = N + 2; //the boundries
    int temp_N_half = temp_N / 2;
    // Declare relative coordinates
    double x = -1.0;
    double y = -1.0;
    double x_lower = 0.0;
    double x_upper = 1.0 / 3.0;
    double y_lower = -2.0 / 3.0;
    double y_upper = -1.0 / 3.0;
    int i, j;
    for (i = 0; i < temp_N; i++)
    {
        for (j = 0; j < temp_N; j++)
        {
            F[i * (temp_N) + j] = 0.0;
            if (i >= temp_N_half)
            {
                U1[(i - temp_N_half) * (temp_N) + j] = 0.0;
                U_old1[(i - temp_N_half) * (temp_N) + j] = 0.0;
            }
            else
            {
                U0[i * (temp_N) + j] = 0.0;
                U_old0[i * (temp_N) + j] = 0.0;
            }
            // Place radiator for F in the right place
            if (x <= x_upper && x >= x_lower && y <= y_upper && y >= y_lower)
            {
                // Set radiator value to 200 degrees
                F[i * temp_N + j] = 200.0;
            }
            // Place temperature for walls
            if (i == (temp_N - 1) || i == 0 || j == (temp_N - 1))
            {
                if (i >= temp_N_half)
                {
                    // Set temperature to 20 degrees for 3 of the walls
                    U1[(i - temp_N_half) * (temp_N) + j] = 20.0;
                    U_old1[(i - temp_N_half) * (temp_N) + j] = 20.0;
                }
                else
                {
                    // Set temperature to 20 degrees for 3 of the walls
                    U0[i * (temp_N) + j] = 20.0;
                    U_old0[i * (temp_N) + j] = 20.0;
                }
            }
            // Move relative coordinates by one unit of grid spacing
            y += delta;

        }
        // Move relative coordinates by one unit of grid spacing
        x += delta;
        y = -1.0;

    }

}

__global__ void jacobi(int N, int temp_N_half, double delta2, double *U, double *U_old, double *U_other, double *F, int device)
{
    int i = blockDim.x * blockIdx.x + threadIdx.x + 1;
    int j = blockDim.y * blockIdx.y + threadIdx.y + 1;
    if (device)
    {
        j = j - 1;
    }
    if (((device && j < temp_N_half - 1) || (!device && j < temp_N_half)) && i < N - 1 && i > 0)
    {
        // Calculate new value from surrounding points
        if (!device && (j == temp_N_half - 1))
        {
            U_old[j * N + i] = (U[j * N + (i - 1)] + U[j * N + (i + 1)] + U[(j - 1) * N + i] + U_other[/*(i+1) * N +*/i] + (delta2 * F[j * N + i])) * 0.25;
        }
        else if (device && !j)
        {
            U_old[j * N + i] = (U[j * N + (i - 1)] + U[j * N + (i + 1)] + U_other[(temp_N_half - 1) * N + i] + U[(j + 1) * N + i] + (delta2 * F[j * N + i])) * 0.25;
        }
        else
        {
            U_old[j * N + i] = (U[j * N + (i - 1)] + U[j * N + (i + 1)] + U[(j - 1) * N + i] + U[(j + 1) * N + i] + (delta2 * F[j * N + i])) * 0.25;
        }
    }
}

void print_matrix(int N, double *M0, double *M1)
{
    int temp_N = N + 2;
    int temp_N_half = temp_N / 2;
    int i, j;
    for (i = 0; i < temp_N; i++)
    {
        for (j = 0; j < temp_N; j++)
        {
            // Swap indecies to show correct x and y-axes
            if (i >= temp_N_half)
            {
                printf("%.2f\t", M1[(i - temp_N_half) * temp_N + j]);
            }
            else
            {
                printf("%.2f\t", M0[i * temp_N + j]);
            }
        }
        printf("\n");
    }
}

int main(int argc, char *argv[])
{

    int N = 16;
    int k = 1000;

    if (argc > 1)
    {
        N = atoi(argv[1]);
    }
    if (argc > 2)
    {
        k = atoi(argv[2]);
    }

    int temp_N = N + 2;
    int size = temp_N * temp_N * sizeof(double);
    double delta = 2.0 / ((double) N - 1.0);
    double delta2 = delta * delta;

    dim3 DimBlock(BLOCK_SIZE, BLOCK_SIZE / 2);
    dim3 DimGrid((N + BLOCK_SIZE - 1) / BLOCK_SIZE, (N + BLOCK_SIZE - 1) / BLOCK_SIZE);

    double *U_dev0;
    double *U_dev1;
    double *U_old_dev0;
    double *U_old_dev1;
    double *F_dev1;
    double *F_dev0;
    double *temp;

    double *U_host0;
    double *U_host1;
    double *U_old_host0;
    double *U_old_host1;
    double *F_host;

    //alloctating memory on host
    U_host0 = (double *) malloc(size / 2);
    U_old_host0 = (double *) malloc(size / 2);
    U_host1 = (double *) malloc(size / 2);
    U_old_host1 = (double *) malloc(size / 2);
    F_host = (double *) malloc(size);

    //initializing the arrays
    init(N, delta, U_host0, U_old_host0, U_host1, U_old_host1, F_host);

    //allocating memory on device0
    checkCudaErrors(cudaSetDevice(0));
    checkCudaErrors(cudaMalloc((void **) &U_dev0, size / 2));
    checkCudaErrors(cudaMalloc((void **) &U_old_dev0, size / 2));
    checkCudaErrors(cudaMalloc((void **) &F_dev0, size));
    //allocating memory on device1
    cudaSetDevice(1);
    cudaDeviceEnablePeerAccess(0, 0);
    checkCudaErrors(cudaMalloc((void **) &U_dev1, size / 2));
    checkCudaErrors(cudaMalloc((void **) &U_old_dev1, size / 2));
    checkCudaErrors(cudaMalloc((void **) &F_dev1, size));

    //copying memory from CPU to GPU
    checkCudaErrors(cudaMemcpy(U_dev1, U_host1, size / 2, cudaMemcpyHostToDevice));
    checkCudaErrors(cudaMemcpy(U_old_dev1, U_old_host1, size / 2, cudaMemcpyHostToDevice));
    checkCudaErrors(cudaMemcpy(F_dev1, F_host, size, cudaMemcpyHostToDevice));

    cudaSetDevice(0);
    cudaDeviceEnablePeerAccess(1, 0);
    checkCudaErrors(cudaMemcpy(U_dev0, U_host0, size / 2, cudaMemcpyHostToDevice));
    checkCudaErrors(cudaMemcpy(U_old_dev0, U_old_host0, size / 2, cudaMemcpyHostToDevice));
    checkCudaErrors(cudaMemcpy(F_dev0, F_host, size, cudaMemcpyHostToDevice));

    int h;
    for (h = 0; h < k; h++)
    {
        cudaSetDevice(0);
        jacobi <<< DimGrid, DimBlock>>>(temp_N, temp_N / 2, delta2, U_dev0, U_old_dev0, U_dev1, F_dev0, 0);
        cudaSetDevice(1);
        jacobi <<< DimGrid, DimBlock>>>(temp_N, temp_N / 2, delta2, U_dev1, U_old_dev1,  U_dev0, F_dev1, 1);
        checkCudaErrors(cudaDeviceSynchronize());
        //swapping pointers
        temp = U_dev0;
        U_dev0 = U_old_dev0;
        U_old_dev0 = temp;
        temp = U_dev1;
        U_dev1 = U_old_dev1;
        U_old_dev1 = temp;
    }
    checkCudaErrors(cudaMemcpy(U_host1, U_dev1, size / 2, cudaMemcpyDeviceToHost));
    cudaSetDevice(0);
    checkCudaErrors(cudaMemcpy(U_host0, U_dev0, size / 2, cudaMemcpyDeviceToHost));
    if (argc > 3)
    {
        if (!strcmp(argv[3], "p"))
        {
            print_matrix(N, U_host0, U_host1);
        }
    }
    //freeing the memory in the end
    free(U_host0);
    free(U_old_host0);
    free(U_host1);
    free(U_old_host1);
    free(F_host);
    checkCudaErrors(cudaFree(U_dev0));
    checkCudaErrors(cudaFree(U_old_dev0));
    checkCudaErrors(cudaFree(F_dev0));
    cudaSetDevice(1);
    checkCudaErrors(cudaFree(U_dev1));
    checkCudaErrors(cudaFree(U_old_dev1));
    checkCudaErrors(cudaFree(F_dev1));
    return 0;
}
