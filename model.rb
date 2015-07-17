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

require 'sequel'
require 'travis'


module Nightlies
  class Model
    def self.db
      @db ||= Sequel.connect(ENV['DATABASE_URL'])
    end

    def self.schema!
      db.create_table(:nightlies) do
        primary_key :id
        String :username
        String :owner
        String :name
        String :travis_token
        Time :last_nightly # Because the API doesn't see API-initiated builds.
        unique [:owner, :name]
      end
    end

    def self.enable!(user, repo_id, slug)
      owner, name = slug.split('/', 2)
      values = {owner: owner, name: name, username: user.login, travis_token: user.attribs['travis_token']}
      if db[:nightlies].filter(id: repo_id).update(values) == 0
        db[:nightlies].insert(values.merge(id: repo_id))
      end
    end

    def self.disable!(user, repo_id)
      db[:nightlies].filter(id: repo_id).update(travis_token: nil)
    end

    def self.by_id(repo_id)
      db[:nightlies].filter(id: repo_id).first
    end

    def self.run!
      db[:nightlies].each do |data|
        # Skip disabled repos.
        next unless data[:travis_token]
        slug = "#{data[:owner]}/#{data[:name]}"
        puts "Checking #{slug}."
        travis = Travis::Client.new(access_token: data[:travis_token])
        repo = travis.repo(slug)
        # Could speed this up in the future.
        last_push_build = repo.builds(event_type: 'push').first
        last_api_build = repo.builds(event_type: 'api').first
        if (last_push_build && last_push_build.pending?) || (last_api_build && last_api_build.pending?)
          # Currently building, we're done here.
          puts "Already building #{slug}"
          next
        end
        build_times = [data[:last_nightly] || Time.at(0)]
        build_times << last_push_build.finished_at if last_push_build
        build_times << last_api_build.finished_at if last_api_build
        last_build_time = build_times.max
        # Check if it has been 24 hours since the last build.
        if Time.now - last_build_time > 60*60*24
          puts "Requesting a build of #{slug}, last build time #{last_build_time}."
          self.run_build!(travis, slug)
          db[:nightlies].filter(id: data[:id]).update(last_nightly: Time.now)
        end
      end
    end

    def self.run_build!(travis, slug)
      encoded_slug = slug.gsub(/\//, '%2F')
      url = "/repo/#{encoded_slug}/requests"
      body = {
        request: {
          branch: 'master',
          message: "Nightly build for #{slug} via nightli.es.",
        },
      }
      headers = {
        'Travis-API-Version' => 3,
      }
      travis.post_raw(url, body, headers)
    end

  end
end
