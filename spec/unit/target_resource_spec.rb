require_relative '../spec_helper'

RSpec.describe StructCore::Processor::TargetResourcesComponent do
	describe 'process' do
		describe 'when provided a spec structure' do
			before(:each) do
				@res_stub = instance_double('StructCore::Processor::TargetResourceComponent')
				allow(@res_stub).to receive(:process).and_return(123)
				@resource_component = StructCore::Processor::TargetResourceComponent.new(
					:spec,
					''
				)
			end

			it 'processes a resource file' do
				project = Xcodeproj::Project.new('abc.xcodeproj')
				res_file = File.join(File.dirname(__FILE__), '../support/processor/res_multiple/Base.lproj/A.storyboard')
				ref = project.new_file res_file

				file = nil
				expect { file = @resource_component.process(ref) }.to_not raise_error
				expect(file).to be_truthy
			end
		end

		describe 'when provided an xcodeproj structure' do
			before(:each) do
				@res_stub = instance_double('StructCore::Processor::TargetResourceComponent')
				allow(@res_stub).to receive(:process)
				@resource_component = StructCore::Processor::TargetResourceComponent.new(
					:xcodeproj,
					''
				)
			end

			it 'processes a resource file' do
				project = Xcodeproj::Project.new('abc.xcodeproj')
				target_dsl = project.new_target(:application, 'ABC', :ios, nil, nil, :swift)

				expect { @resource_component.process(File.join(File.dirname(__FILE__), '../support/processor/res_multiple/Base.lproj/A.storyboard'), target_dsl, project) }.to_not raise_error
			end
		end
	end
end