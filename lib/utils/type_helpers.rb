module StructCore
	module TypeHelpers
		def typed_default(obj, type, default)
			return default unless obj.is_a? type
			obj
		end
	end
end