# Cloud Foundry Java Buildpack
# Copyright 2013-2017 the original author or authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'fileutils'
require 'yaml'
require 'java_buildpack/component/versioned_dependency_component'
require 'java_buildpack/logging/logger_factory'
require 'java_buildpack/framework'

module JavaBuildpack
  module Framework

    # Encapsulates the detect, compile, and release functionality for enabling cloud auto-reconfiguration in Spring
    # applications.
    class SnykAutoPatch < JavaBuildpack::Component::VersionedDependencyComponent

      # Creates an instance
      #
      # @param [Hash] context a collection of utilities used the component
      def initialize(context)
        super(context)
        @logger = JavaBuildpack::Logging::LoggerFactory.instance.get_logger SnykAutoPatch
      end

      # (see JavaBuildpack::Component::BaseComponent#compile)
      # This is to change the FS
      def compile
        uri = URI(@configuration['repository_root'] + '/snyk.config')
        config_data = Net::HTTP.get(uri)
        config = YAML.load(config_data)
        config["patch"].keys.each do |key|
          jar_to_patch = config["patch"][key]["patch"]
          puts jar_to_patch
          download_jar(jar_name=jar_to_patch)
          FileUtils.remove_file  @droplet.root + 'WEB-INF/lib/' + jar_to_patch
          @droplet.additional_libraries << (@droplet.sandbox + jar_to_patch)
        end
      end

      # (see JavaBuildpack::Component::BaseComponent#release)
      # This is for runtime configuration (Env var and etc..)
      def release
      end

      protected

      # (see JavaBuildpack::Component::VersionedDependencyComponent#supports?)
      def supports?
        @configuration['enabled']
      end
    end

  end
end
