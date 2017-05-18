require_relative '../spec_helper'

RSpec.describe StructCore::SpecProcessor do
	describe 'process' do
		def self.test_input(name, file)
			it "can handle #{name} inputs" do
				processor = StructCore::SpecProcessor.new(file, true, [])
				allow(processor).to receive(:process_source_dsl).and_return({})

				ret_val = StructCore::Processor::ProcessorOutput.new({}, 'abc')
				project_component = instance_double('StructCore::Processor::ProjectComponent')
				allow(project_component).to receive(:process).and_return([ret_val])

				outputs = []
				expect { outputs = processor.process(project_component) }.to_not raise_error
				expect(outputs.count).to eq(1)
			end
		end

		test_input 'xcodeproj', 'a.xcodeproj'
		test_input 'yml', 'a.yml'
		test_input 'yaml', 'a.yaml'
		test_input 'json', 'a.json'
		test_input 'Specfile', 'Specfile'

		it 'raises with an unrecognised input' do
			processor = StructCore::SpecProcessor.new('abc.def', true, [])
			allow(processor).to receive(:process_source_dsl).and_return({})

			project_component = instance_double('StructCore::Processor::ProjectComponent')

			expect { processor.process(project_component) }.to raise_error
		end

		it 'prints processing output for xcodeproj outputs' do
			processor = StructCore::SpecProcessor.new('a.yml', true, [])
			allow(processor).to receive(:process_source_dsl).and_return({})
			allow(processor).to receive(:print)

			xcodeproj = instance_double('Xcodeproj::Project')
			allow(xcodeproj).to receive(:is_a?).and_return(false)
			allow(xcodeproj).to receive(:is_a?).with(Xcodeproj::Project).and_return(true)
			ret_val = StructCore::Processor::ProcessorOutput.new(xcodeproj, 'abc.xcodeproj')
			project_component = instance_double('StructCore::Processor::ProjectComponent')
			allow(project_component).to receive(:process).and_return([ret_val])

			expect { processor.process(project_component) }.to_not raise_error
			expect(processor).to have_received(:print)
		end

		it 'prints processing output for spec outputs' do
			processor = StructCore::SpecProcessor.new('a.xcodeproj', true, [])
			allow(processor).to receive(:process_source_dsl).and_return({})
			allow(processor).to receive(:print)

			spec = instance_double('StructCore::Specfile')
			allow(spec).to receive(:is_a?).and_return(false)
			allow(spec).to receive(:is_a?).with(StructCore::Specfile).and_return(true)
			ret_val = StructCore::Processor::ProcessorOutput.new(spec, 'abc.yml')
			project_component = instance_double('StructCore::Processor::ProjectComponent')
			allow(project_component).to receive(:process).and_return([ret_val])

			expect { processor.process(project_component) }.to_not raise_error
			expect(processor).to have_received(:print)
		end
	end
end