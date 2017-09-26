require_relative 'spec_scheme_build_dsl_30X'
require_relative 'spec_scheme_profile_dsl_30X'
require_relative 'spec_scheme_launch_dsl_30X'
require_relative 'spec_scheme_test_dsl_30X'

module StructCore
	class SpecSchemeDSL30X
		attr_accessor :current_scope, :scheme, :project

		def initialize
			@scheme = nil
			@current_scope = nil
			@project = nil
		end

		def archive(opts = {})
			return unless opts.key?(:name) && opts.key?(:reveal)
			return unless opts[:name].is_a?(String) && !opts[:name].empty?

			reveal = true
			reveal = opts[:reveal] if opts.key? :reveal

			build_configuration = nil
			build_configuration = opts[:build_configuration] if opts.key? :build_configuration

			@scheme.archive_action = StructCore::Specfile::Scheme::ArchiveAction.new opts[:name], reveal, build_configuration
		end

		def analyze(opts = {})
			build_configuration = nil
			build_configuration = opts[:build_configuration] if opts.key? :build_configuration

			@scheme.analyze_action = StructCore::Specfile::Scheme::AnalyzeAction.new build_configuration
		end

		def build(&block)
			return if block.nil?
			dsl = StructCore::SpecSchemeBuildDSL30X.new

			@current_scope = dsl
			dsl.build_action = StructCore::Specfile::Scheme::BuildAction.new
			block.call
			@current_scope = nil

			@scheme.build_action = dsl.build_action
		end

		def launch(target_name = nil, &block)
			return unless target_name.is_a?(String) && !target_name.empty? && !block.nil?
			dsl = StructCore::SpecSchemeLaunchDSL30X.new

			@current_scope = dsl
			dsl.launch_action = StructCore::Specfile::Scheme::LaunchAction.new target_name
			dsl.project = @project
			block.call
			@current_scope = nil

			@scheme.launch_action = dsl.launch_action
		end

		def profile(target_name = nil, &block)
			return unless target_name.is_a?(String) && !target_name.empty? && !block.nil?
			dsl = StructCore::SpecSchemeProfileDSL30X.new

			@current_scope = dsl
			dsl.profile_action = StructCore::Specfile::Scheme::ProfileAction.new target_name
			dsl.project = @project
			block.call
			@current_scope = nil

			@scheme.profile_action = dsl.profile_action
		end

		def tests(build_configuration = nil, &block)
			return unless build_configuration.is_a?(String) && !build_configuration.empty? && !block.nil?
			dsl = StructCore::SpecSchemeTestDSL30X.new

			@current_scope = dsl
			dsl.test_action = StructCore::Specfile::Scheme::TestAction.new build_configuration
			dsl.project = @project
			block.call
			@current_scope = nil

			@scheme.test_action = dsl.test_action
		end

		def respond_to_missing?(_, _)
			true
		end

		def method_missing(method, *args, &block)
			return if @current_scope.nil?
			@current_scope.send(method, *args, &block)
		end
	end
end