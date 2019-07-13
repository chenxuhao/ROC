/* Copyright 2019 Stanford
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include "initializer.h"
#include "types.h"
#include "cuda_helper.h"
#include <curand.h>
#include <ctime>

void GlorotUniform::init_task(const Task* task,
                              const std::vector<PhysicalRegion>& regions,
                              Context ctx, Runtime* runtime)
{
  assert(regions.size() == 1);
  assert(task->regions.size() == 1);
  TensorAccessorW<DATATYPE, 2> accW(
      regions[0], task->regions[0], FID_DATA, ctx, runtime, NULL,
      false/*readOutput*/);
  int inputDim = accW.rect.hi[0] - accW.rect.lo[0] + 1;
  int outputDim = accW.rect.hi[1] - accW.rect.lo[1] + 1;
  // TODO: remove me
  //assign_kernel<<<GET_BLOCKS(accW.rect.volume()), CUDA_NUM_THREADS>>>(
  //    accW.ptr, accW.rect.volume(), 1.0/64);
  //return;
  //float scale = *((float*) task->args);
  float scale = sqrt(6.0 / (inputDim + outputDim));
  printf("scale = %.4lf\n", scale);
  curandGenerator_t gen;
  curandCreateGenerator(&gen, CURAND_RNG_PSEUDO_DEFAULT);
  // TODO: change to random seed before releasing
  int seed = *((int*) task->args);
  fprintf(stderr, "seed = %d\n", seed);
  curandSetPseudoRandomGeneratorSeed(gen, seed);
  checkCUDA(curandGenerateUniform(gen, accW.ptr, accW.rect.volume()));
  scale_kernel<<<GET_BLOCKS(accW.rect.volume()), CUDA_NUM_THREADS>>>(
      accW.ptr, accW.rect.volume(), -scale, scale);
  checkCUDA(cudaDeviceSynchronize());
  curandDestroyGenerator(gen);
}

void ZerosInitializer::init_task(const Task* task,
                                 const std::vector<PhysicalRegion>& regions,
                                 Context ctx, Runtime* runtime)
{
  assert(regions.size() == 1);
  assert(task->regions.size() == 1);
  TensorAccessorW<DATATYPE, 2> accW(
      regions[0], task->regions[0], FID_DATA, ctx, runtime, NULL,
      false/*readOutput*/);
  assign_kernel<<<GET_BLOCKS(accW.rect.volume()), CUDA_NUM_THREADS>>>(
      accW.ptr, accW.rect.volume(), 0);
  checkCUDA(cudaDeviceSynchronize());
}

void zero_grad_task_impl(const Task* task,
                         const std::vector<PhysicalRegion>& regions,
                         Context ctx, Runtime* runtime)
{
  assert(regions.size() == task->regions.size());
  for (size_t i = 0; i < regions.size(); i++) {
    Domain domain = runtime->get_index_space_domain(
        ctx, task->regions[i].region.get_index_space());
    DATATYPE* w;
    switch (domain.get_dim()) {
      case 0:
      {
        // Do not support 0-dim parameters
        assert(false);
        break;
      }
      case 1:
      {
        TensorAccessorW<DATATYPE, 1> accW(
            regions[i], task->regions[i], FID_DATA, ctx, runtime, NULL,
            false/*readOutput*/);
        w = accW.ptr;
        break;
      }
      case 2:
      {
        TensorAccessorW<DATATYPE, 2> accW(
            regions[i], task->regions[i], FID_DATA, ctx, runtime, NULL,
            false/*readOutput*/);
        w = accW.ptr;
        break;
      }
      case 3:
      {
        TensorAccessorW<DATATYPE, 3> accW(
            regions[i], task->regions[i], FID_DATA, ctx, runtime, NULL,
            false/*readOutput*/);
        w = accW.ptr;
        break;
      }
      default:
      {
         assert(false);
         break;
      }
    }
    assign_kernel<<<GET_BLOCKS(domain.get_volume()), CUDA_NUM_THREADS>>>(
        w, domain.get_volume(), 0.0f);
  }
  checkCUDA(cudaDeviceSynchronize());
}
