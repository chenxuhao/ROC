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

#include "gnn.h"

ResourceManager::ResourceManager(void)
{}

ResourceManager::~ResourceManager(void)
{}

int ResourceManager::assign(LogicalRegion lr,
                            size_t numElement,
                            std::set<int>& assigned)
{
  // See if we have lr on one cache
  for (int i = 0; i < MAX_NUM_CACHES; i++) {
    if (fbCache[i].region == lr) {
      printf("[%d] numElement(%zu) volume(%zu)\n", i, numElement, fbCache[i].volume);
      assert(numElement <= fbCache[i].volume);
      assigned.insert(i);
      return i;
    }
  }
  int bestId = -1;
  // If not, assign lr to the smallest available cache
  for (int i = 0; i < MAX_NUM_CACHES; i++) {
    if ((assigned.find(i) == assigned.end())
    && (fbCache[i].volume >= numElement)) {
      if ((bestId == -1) || (fbCache[i].volume < fbCache[bestId].volume)) {
        bestId = i;
      }
    }
  }

  assert(bestId != -1);
  fbCache[bestId].region = lr;
  assigned.insert(bestId);
  return bestId;
}