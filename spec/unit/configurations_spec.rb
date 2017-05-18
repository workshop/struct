require_relative '../spec_helper'

RSpec.describe StructCore::Processor::ConfigurationsComponent do
	describe 'process' do
		describe 'when provided a spec structure' do
			before(:each) do
				@config_stub = instance_double('StructCore::Processor::ConfigurationComponent')
				allow(@config_stub).to receive(:process).and_return(123)
				@configs_component = StructCore::Processor::ConfigurationsComponent.new(
					:spec,
					'',
					@config_stub
				)
			end

			it 'processes any present configurations' do
				project = Xcodeproj::Project.new('abc.xcodeproj')
				project.add_build_configuration('Debug', :debug)

				spec = nil
				expect { spec = @configs_component.process(project).first }.to_not raise_error
				expect(spec).to be_truthy
			end
		end

		describe 'when provided a xcodeproj structure' do
			before(:each) do
				@config_stub = instance_double('StructCore::Processor::ConfigurationComponent')
				allow(@config_stub).to receive(:process)
				@configs_component = StructCore::Processor::ConfigurationsComponent.new(
					:xcodeproj,
					'',
					@config_stub
				)
			end

			it 'processes any present configurations' do
				project = StructCore::Specfile.new(nil, [], [StructCore::Specfile::Configuration.new('', [], {})], [], '')

				expect(@config_stub).to receive(:process)
				expect { @configs_component.process(project, Xcodeproj::Project.new('abc.xcodeproj')) }.to_not raise_error
			end
		end
	end
end