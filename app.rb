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
require 'tilt/erb'
require 'librato-rack'

require_relative './model'
require_relative './warden_travis/strategy'

module Nightlies
  class Application < Sinatra::Application
    configure do
      # Let's get this party started!
      enable :sessions
      set :session_secret, ENV['GITHUB_VERIFIER_SECRET']
      set :public_folder, 'public'
      use Rack::Protection::AuthenticityToken

      # Load librato
      use Librato::Rack if ENV['LIBRATO_TOKEN']

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
    end

    helpers do
      def travis_token
        authenticated? && github_user.attribs['travis_token']
      end

      def travis_api
        raise "No travis token" unless travis_token
        Travis::Client.new(access_token: travis_token, agent_info: 'nightli.es')
      end

      def no_cache!
        cache_control :no_cache, :no_store, :must_revalidate
        headers['Expires'] = '0'
        headers['Pragma'] = 'no-cache'
      end
    end

    before do
      headers 'Content-Type' => 'text/html; charset=utf8'
    end

    get '/' do
      no_cache!
      if !authenticated?
        erb :landing
      else
        @repos = travis_api.get_raw('/hooks')['hooks'].inject([]) do |memo, data|
          if data['admin'] && data['active']
            row = Nightlies::Model.by_id(data['id'])
            memo << data.merge(
              'last_nightly' => row && row[:last_nightly],
              'enabled' => row && !!row[:travis_token],
            )
          end
          memo
        end
        @extra_js = 'dashboard.js'
        erb :dashboard
      end
    end

    get '/login' do
      no_cache!
      authenticate!
      redirect '/'
    end

    get '/logout' do
      no_cache!
      logout!
      redirect '/'
    end

    post '/enable/:id' do
      logger.warn "Enabling nightly builds for #{params['slug']} via #{github_user.login}"
      Nightlies::Model.enable!(github_user, params['id'].to_i, params['slug'])
      content_type :json
      {success: true}.to_json
    end

    post '/disable/:id' do
      logger.warn "Disabling nightly builds for #{params['slug']} via #{github_user.login}"
      Nightlies::Model.disable!(github_user, params['id'].to_i)
      content_type :json
      {success: true}.to_json
    end

    run! if app_file == $0
  end
end
