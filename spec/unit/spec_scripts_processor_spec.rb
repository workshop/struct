require_relative '../spec_helper'

RSpec.describe StructCore::SpecScriptsProcessor do
	describe 'pre_generate' do
		it 'skips executing the hook when not provided a Specfile DSL' do
			expect { StructCore::SpecScriptsProcessor.new.pre_generate 123 }.to_not raise_error
		end

		it 'skips executing the hook when the hook does not exist' do
			spec = StructCore::Specfile.new nil, [], [], [], nil, false, nil, nil
			expect { StructCore::SpecScriptsProcessor.new.pre_generate spec }.to_not raise_error
		end

		it 'executes script file hooks' do
			script = StructCore::Specfile::HookScript.new File.join(File.dirname(__FILE__), '../support/processor/pre-generate.rb')
			spec = StructCore::Specfile.new nil, [], [], [], nil, false, script, nil
			expect { StructCore::SpecScriptsProcessor.new.pre_generate spec }.to_not raise_error
		end

		it 'executes block hooks' do
			block = proc { |spec| puts spec }
			script = StructCore::Specfile::HookBlockScript.new block
			spec = StructCore::Specfile.new nil, [], [], [], nil, false, script, nil
			expect { StructCore::SpecScriptsProcessor.new.pre_generate spec }.to_not raise_error
		end
	end

	describe 'post_generate' do
		it 'skips executing the hook when not provided a Specfile DSL' do
			expect { StructCore::SpecScriptsProcessor.new.post_generate 123, 456 }.to_not raise_error
		end

		it 'skips executing the hook when not provided a Xcodeproj::Project DSL' do
			spec = StructCore::Specfile.new nil, [], [], [], nil, false, nil, nil
			expect { StructCore::SpecScriptsProcessor.new.post_generate spec, 456 }.to_not raise_error
		end

		it 'skips executing the hook when the hook does not exist' do
			spec = StructCore::Specfile.new nil, [], [], [], nil, false, nil, nil
			proj = Xcodeproj::Project.new 'abc.xcodeproj'
			expect { StructCore::SpecScriptsProcessor.new.post_generate spec, proj }.to_not raise_error
		end

		it 'executes script file hooks' do
			script = StructCore::Specfile::HookScript.new File.join(File.dirname(__FILE__), '../support/processor/post-generate.rb')
			spec = StructCore::Specfile.new nil, [], [], [], nil, false, nil, script
			proj = Xcodeproj::Project.new 'abc.xcodeproj'
			expect { StructCore::SpecScriptsProcessor.new.post_generate spec, proj }.to_not raise_error
		end

		it 'executes block hooks' do
			block = proc { |spec, xcodeproj|
				puts spec
				puts xcodeproj
			}
			script = StructCore::Specfile::HookBlockScript.new block
			spec = StructCore::Specfile.new nil, [], [], [], nil, false, nil, script
			proj = Xcodeproj::Project.new 'abc.xcodeproj'
			expect { StructCore::SpecScriptsProcessor.new.post_generate spec, proj}.to_not raise_error
		end
	end
end