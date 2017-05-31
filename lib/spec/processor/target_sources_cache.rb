module StructCore
	module Processor
		class TargetSourcesCache
			def initialize
				@cache = {}
			end

			def ref(source_file, rel_file, group)
				ref = @cache[source_file]
				ref = group.new_file File.basename(rel_file) if ref.nil?
				@cache[source_file] = ref

				ref
			end
		end
	end
end