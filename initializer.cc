/* Copyright 2019 Stanford
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
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
#include "gnn.h"

Initializer::Initializer(void)
{}

Initializer::~Initializer(void)
{}

GlorotUniform::GlorotUniform(void)
: Initializer() {}

GlorotUniform::~GlorotUniform(void)
{}

void GlorotUniform::init(const Model* model,
                         const Tensor* p)
{
  Context ctx = model->ctx;
  Runtime* runtime = model->runtime;
  assert(p->numDim == 2);
  float scale = sqrt(6.0 / (p->dims[0] + p->dims[1]));
  TaskLauncher launcher(GLOROT_INIT_TASK_ID, TaskArgument(&scale, sizeof(float)));
  // regions[0]: p->region
  launcher.add_region_requirement(
      RegionRequirement(p->region,
                        WRITE_ONLY, EXCLUSIVE, p->region,
                        MAP_TO_FB_MEMORY));
  launcher.add_field(0, FID_DATA);
  runtime->execute_task(ctx, launcher);
}

ZerosInitializer::ZerosInitializer(void)
: Initializer() 
{}

ZerosInitializer::~ZerosInitializer(void)
{}

void ZerosInitializer::init(const Model* model,
                            const Tensor* p)
{
  Context ctx = model->ctx;
  Runtime* runtime = model->runtime;
  assert(p->numDim == 2);
  TaskLauncher launcher(ZEROS_INIT_TASK_ID, TaskArgument(NULL, 0));
  // regions[0]: p->region
  launcher.add_region_requirement(
      RegionRequirement(p->region,
                        WRITE_ONLY, EXCLUSIVE, p->region,
                        MAP_TO_FB_MEMORY));
  launcher.add_field(0, FID_DATA);
  runtime->execute_task(ctx, launcher);
}
