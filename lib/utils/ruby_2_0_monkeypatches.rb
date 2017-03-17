unless [].respond_to? :to_h
	class Array
		def to_h
			Hash[self]
		end
	end
end