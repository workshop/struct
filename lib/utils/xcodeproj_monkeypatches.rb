module Xcodeproj
	class Project
		module Object
			class FileReferencesFactory
				def self.struct__new_reference(group, path, source_tree)
					ref =
						case File.extname(path).downcase
						when '.xcdatamodeld'
							new_xcdatamodeld(group, path, source_tree)
						when '.xcodeproj'
							struct__new_subproject(group, path, source_tree)
						else
							new_file_reference(group, path, source_tree)
						end

					configure_defaults_for_file_reference(ref)
					ref
				end

				def self.struct__process_proxies_for_group(group, products_group, ref, product_group_ref)
					products_group.files.each do |product_reference|
						container_proxy = group.project.new(PBXContainerItemProxy)
						container_proxy.container_portal = ref.uuid
						container_proxy.proxy_type = Constants::PROXY_TYPES[:reference]
						container_proxy.remote_global_id_string = product_reference.uuid
						container_proxy.remote_info = 'Subproject'

						reference_proxy = group.project.new(PBXReferenceProxy)
						extension = File.extname(product_reference.path)[1..-1]
						reference_proxy.file_type = Constants::FILE_TYPES_BY_EXTENSION[extension]
						reference_proxy.path = product_reference.path
						reference_proxy.remote_ref = container_proxy
						reference_proxy.source_tree = 'BUILT_PRODUCTS_DIR'

						product_group_ref << reference_proxy
					end

					products_group.groups.each do |child_group|
						struct__process_proxies_for_group group, child_group, ref, product_group_ref
					end
				end

				def self.struct__new_subproject(group, path, source_tree)
					ref = new_file_reference(group, path, source_tree)
					ref.include_in_index = nil

					product_group_ref = group.project.new(PBXGroup)
					product_group_ref.name = 'Products'
					product_group_ref.source_tree = '<group>'

					subproj = Project.open(path)
					struct__process_proxies_for_group group, subproj.products_group, ref, product_group_ref

					attribute = PBXProject.references_by_keys_attributes.find { |attrb| attrb.name == :project_references }
					project_reference = ObjectDictionary.new(attribute, group.project.root_object)
					project_reference[:project_ref] = ref
					project_reference[:product_group] = product_group_ref
					group.project.root_object.project_references << project_reference

					ref
				end
			end

			class PBXGroup < AbstractObject
				def struct__new_reference(path, source_tree = :group)
					FileReferencesFactory.struct__new_reference(self, path, source_tree)
				end
			end

			class PBXNativeTarget < AbstractTarget
				def clear_phases
					@build_phases = []
				end
			end
		end
	end
end
