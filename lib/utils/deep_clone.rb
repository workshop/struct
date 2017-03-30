# rubocop:disable Security/MarshalLoad
def deep_clone(object)
	Marshal.load(Marshal.dump(object))
end
# rubocop:enable Security/MarshalLoad