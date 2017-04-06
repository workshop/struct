require_relative 'spec_scheme_analyze_dsl_20X'
require_relative 'spec_scheme_build_dsl_20X'
require_relative 'spec_scheme_profile_dsl_20X'
require_relative 'spec_scheme_launch_dsl_20X'
require_relative 'spec_scheme_test_dsl_20X'

module StructCore
	class SpecSchemeDSL20X
		attr_accessor :current_scope, :scheme

		def initialize
			@scheme = nil
			@current_scope = nil
		end

		def analyze(&block)
			return if block.nil?
			dsl = StructCore::SpecSchemeAnalyzeDSL20X.new

			@current_scope = dsl
			dsl.analyze_action = StructCore::Specfile::Scheme::AnalyzeAction.new
			block.call
			@current_scope = nil

			@scheme.analyze_action = dsl.analyze_action
		end

		def archive(opts = {})
			return unless opts.key?(:name) && opts.key?(:reveal)
			return unless opts[:name].is_a?(String) && !opts[:name].empty?

			reveal = true
			reveal = opts[:reveal] if opts.key? :reveal

			@scheme.archive_action = StructCore::Specfile::Scheme::ArchiveAction.new opts[:name], reveal
		end

		def build(&block)
			return if block.nil?
			dsl = StructCore::SpecSchemeBuildDSL20X.new

			@current_scope = dsl
			dsl.build_action = StructCore::Specfile::Scheme::BuildAction.new
			block.call
			@current_scope = nil

			@scheme.build_action = dsl.build_action
		end

		def launch(target_name = nil, &block)
			return unless target_name.is_a?(String) && !target_name.empty? && !block.nil?
			dsl = StructCore::SpecSchemeLaunchDSL20X.new

			@current_scope = dsl
			dsl.launch_action = StructCore::Specfile::Scheme::LaunchAction.new target_name
			block.call
			@current_scope = nil

			@scheme.launch_action = dsl.launch_action
		end

		def profile(target_name = nil, &block)
			return unless target_name.is_a?(String) && !target_name.empty? && !block.nil?
			dsl = StructCore::SpecSchemeProfileDSL20X.new

			@current_scope = dsl
			dsl.profile_action = StructCore::Specfile::Scheme::ProfileAction.new target_name
			block.call
			@current_scope = nil

			@scheme.profile_action = dsl.profile_action
		end

		def tests(build_configuration = nil, &block)
			return unless build_configuration.is_a?(String) && !build_configuration.empty? && !block.nil?
			dsl = StructCore::SpecSchemeTestDSL20X.new

			@current_scope = dsl
			dsl.test_action = StructCore::Specfile::Scheme::TestAction.new build_configuration
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