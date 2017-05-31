require_relative '../../../utils/ruby_2_0_monkeypatches'

module StructCore
	class SpecTargetScriptDSL20X
		def initialize
			@script = nil
		end

		attr_accessor :script

		def input(param = nil)
			return if param.nil?
			@script.inputs << param
		end

		def output(param = nil)
			return if param.nil?
			@script.outputs << param
		end

		def shell(param = nil)
			return if param.nil?
			@script.shell = param
		end

		def respond_to_missing?(_, _)
			true
		end

		def method_missing(_, *_)
			# Do nothing if a method is missing
		end
	end
end