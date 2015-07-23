#
# Copyright 2015, Noah Kantrowitz
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'benchmark'

require 'snitcher'

require_relative './model'

task :schema do
  Nightlies::Model.schema!
end

task :run do
  time = Benchmark.realtime { Nightlies::Model.run! }
  msg = "Finished in #{time} seconds."
  puts(msg)
  Snitcher.snitch(ENV['SNITCH_ID'], message: msg) if ENV['SNITCH_ID']
end
