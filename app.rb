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

require 'sinatra'
require 'sinatra_auth_github'

require_relative './warden_travis/strategy'

# Let's get this party started!
enable :sessions
set :session_secret, ENV['GITHUB_VERIFIER_SECRET']

# Load the GithHub authentication stuffs.
set :github_options, {scopes: 'read:org user:email repo:status write:repo_hook repo_deployment'}
register Sinatra::Auth::Github

# Reconfigure Warden to use our strategy instead.
use Class.new {
  def initialize(app)
    @app = app
  end
  def call(env)
    env['warden'].config.default_strategies :travis
    @app.call(env)
  end
}

get '/' do
  'Hello world!'
end

get '/login' do
  authenticate!
  "Hello there, #{github_user.login}! #{github_user.attribs['travis_token'].inspect}"
end

get '/logout' do
  logout!
  redirect '/'
end
