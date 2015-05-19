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

require 'travis'
require 'warden/github/strategy'


module Warden
  module Travis
    class Strategy < ::Warden::GitHub::Strategy

      def load_user
        ::Warden::GitHub::User.load(oauth.access_token, custom_session['browser_session_id']).tap do |user|
          ::Travis.github_auth(user.token)
          abort_flow!(e.message) unless ::Travis.access_token
          user.attribs['travis_token'] = ::Travis.access_token
        end
      rescue ::Warden::GitHub::OAuth::BadVerificationCode => e
        abort_flow!(e.message)
      end

    end
  end
end

Warden::Strategies.add(:travis, Warden::Travis::Strategy)
