require_relative 'spec_builder_dsl'
require_relative '../../spec/spec_file'

module StructCore
	class SpecBuilder
		# @param path [String]
		def self.build(path)
			filename = Pathname.new(path).absolute? ? path : File.join(Dir.pwd, path)
			raise StandardError.new "Error: Spec file #{filename} does not exist" unless File.exist? filename

			builder_dsl = StructCore::SpecBuilderDsl.new(StructCore::Specfile.new(nil, [], [], [], File.dirname(filename)))
			builder_dsl.project_base_dir = File.dirname filename
			builder_dsl.instance_eval(File.read(filename))
			spec = validate_spec builder_dsl.build

			# $base variant is implicitly instantiated unless already defined
			if spec.variants.select { |variant| variant.name == '$base' }.count.zero?
				spec.variants.push StructCore::Specfile::Variant.new('$base', [], false)
			end

			spec
		end

		def self.validate_spec(spec)
			raise StandardError.new('Invalid Specfile. The Specfile was empty.') if spec.nil?

			validate_spec_configurations spec.configurations
			validate_spec_targets spec.targets, spec.configurations.count

			spec
		end

		def self.validate_spec_configurations(configs)
			raise StandardError.new('Invalid Specfile. No configurations were defined') if configs.nil? || configs.empty?
			configs.each { |config|
				validate_spec_configuration config
			}
		end

		def self.validate_spec_configuration(config)
			raise StandardError.new('Invalid Specfile. Found invalid configuration') if config.nil?
			raise StandardError.new('Invalid Specfile. Configuration must contain at '\
 			'least one profile, or an xcconfig source') if config.profiles.empty? && (config.source.nil? || config.source.empty?)
		end

		def self.validate_spec_targets(targets, spec_config_count)
			return if targets.nil? || targets.empty?
			targets.each { |target|
				validate_spec_target target, spec_config_count
			}
		end

		def self.validate_spec_target(target, spec_config_count)
			raise StandardError.new('Invalid Specfile. Invalid target object detected') if target.nil?
			raise StandardError.new('Invalid Specfile. No target name was defined') if target.name.nil? || target.name.empty?
			raise StandardError.new('Invalid Specfile. No target type was defined') if target.type.nil?
			raise StandardError.new('Invalid Specfile. No target configurations were found. Ensure you have declared at least'\
			' one project configuration before declaring your target.') if target.configurations.empty?
			raise StandardError.new('Invalid Specfile. The number of target configurations did not match '\
			'the number of project configurations. Please ensure you have declared enough target configurations '\
			'and that these configurations are valid.') unless target.configurations.count == spec_config_count
		end
	end
end