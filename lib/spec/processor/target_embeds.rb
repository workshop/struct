require_relative 'processor_component'

module StructCore
	module Processor
		class TargetEmbedsComponent
			include ProcessorComponent

			def initialize(structure, working_directory, spec = nil)
				super(structure, working_directory)
				@target_map = {}
				@embeddable_target_map = {}
				@target_native_map = {}

				preprocess spec if !spec.nil? && structure == :xcodeproj
			end

			# @param spec [Specfile]
			def preprocess(spec)
				target_map = spec.targets.map { |target|
					[target.name, target]
				}.to_h

				spec.targets.map { |target|
					embedded_targets = target.references.select { |ref|
						ref.is_a?(Specfile::Target::TargetReference)
					}.map { |ref|
						target_map[ref.target_name]
					}.compact.select { |ref_target|
						ref_target.configurations[0].profiles.include?('watchkit2-extension') ||
						ref_target.configurations[0].profiles.include?('application.watchapp2') ||
						ref_target.configurations[0].profiles.include?('tv-broadcast-extension') ||
						ref_target.configurations[0].profiles.include?('app-extension')
					}

					@target_map[target.name] = embedded_targets
					embedded_targets.each { |et|
						if @embeddable_target_map.key? et.name
							@embeddable_target_map[et.name] << target
						else
							@embeddable_target_map[et.name] = [target]
						end
					}
				}
			end

			def register(target, native_target)
				@target_native_map[target.name] = native_target
			end

			def process(dsl)
				process_xc_embeds dsl if structure == :spec
				process_spec_embeds dsl if structure == :xcodeproj
			end

			def process_xc_embeds(dsl) end

			# @param dsl [Xcodeproj::Project]
			def process_spec_embeds(dsl)
				@target_map.each { |target_name, embedded_targets|
					embed_watch_content_phase = dsl.new(Xcodeproj::Project::Object::PBXCopyFilesBuildPhase)
					embed_watch_content_phase.name = 'Embed Watch Content'
					embed_watch_content_phase.dst_subfolder_spec = '16'
					embed_watch_content_phase.dst_path = '$(CONTENTS_FOLDER_PATH)/Watch'

					embed_app_extensions_phase = dsl.new(Xcodeproj::Project::Object::PBXCopyFilesBuildPhase)
					embed_app_extensions_phase.name = 'Embed App Extensions'
					embed_app_extensions_phase.symbol_dst_subfolder_spec = :plug_ins

					native_target = @target_native_map[target_name]
					next if native_target.nil?

					embedded_native_targets = embedded_targets.map { |et| [et, @target_native_map[et.name]] }
					next if embedded_native_targets.count != embedded_targets.count

					embedded_native_targets.each { |pair|
						embedded_target, embedded_native_target = pair

						embed_application_watchapp2 embedded_target, embedded_native_target, embed_watch_content_phase
						embed_watchkit2_extension embedded_target, embedded_native_target, embed_app_extensions_phase
						embed_tv_broadcast_extension embedded_target, embedded_native_target, embed_app_extensions_phase
						embed_application_extension embedded_target, embedded_native_target, embed_app_extensions_phase
					}

					native_target.build_phases.insert(native_target.build_phases.count, embed_watch_content_phase) unless embed_watch_content_phase.files.empty?
					native_target.build_phases.insert(native_target.build_phases.count, embed_app_extensions_phase) unless embed_app_extensions_phase.files.empty?
				}
			end

			def embed_application_extension(embedded_target, embedded_native_target, embed_watch_content_phase)
				return unless embedded_target.configurations[0].profiles.include? 'app-extension'
				embed_watch_content_phase.add_file_reference embedded_native_target.product_reference
			end

			def embed_application_watchapp2(embedded_target, embedded_native_target, embed_watch_content_phase)
				return unless embedded_target.configurations[0].profiles.include? 'application.watchapp2'
				embed_watch_content_phase.add_file_reference embedded_native_target.product_reference
			end

			def embed_watchkit2_extension(embedded_target, embedded_native_target, embed_app_extensions_phase)
				return unless embedded_target.configurations[0].profiles.include? 'watchkit2-extension'
				embed_app_extensions_phase.add_file_reference embedded_native_target.product_reference
			end

			def embed_tv_broadcast_extension(embedded_target, embedded_native_target, embed_app_extensions_phase)
				return unless embedded_target.configurations[0].profiles.include? 'tv-broadcast-extension'
				embed_app_extensions_phase.add_file_reference embedded_native_target.product_reference
			end

			private :embed_application_watchapp2
			private :embed_watchkit2_extension
		end
	end
end