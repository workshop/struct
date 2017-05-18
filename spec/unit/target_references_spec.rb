require_relative '../spec_helper'

RSpec.describe StructCore::Processor::TargetReferencesComponent do
	describe 'process' do
		describe 'when provided a spec structure' do
			before(:each) do
				@system_ref_component = instance_double('TargetSystemFrameworkReferenceComponent')
				allow(@system_ref_component).to receive(:process).and_return(123)
				@system_lib_ref_component = instance_double('TargetSystemLibraryReferenceComponent')
				allow(@system_lib_ref_component).to receive(:process).and_return(123)
				@local_ref_component = instance_double('TargetLocalFrameworkReferenceComponent')
				allow(@local_ref_component).to receive(:process).and_return(123)
				@local_lib_ref_component = instance_double('TargetLocalLibraryReferenceComponent')
				allow(@local_lib_ref_component).to receive(:process).and_return(123)
				@subproj_ref_component = instance_double('TargetFrameworkReferenceComponent')
				allow(@subproj_ref_component).to receive(:process).and_return(123)
				@target_ref_component = instance_double('TargetTargetReferenceComponent')
				allow(@target_ref_component).to receive(:process).and_return(123)

				@refs_component = StructCore::Processor::TargetReferencesComponent.new(
					:spec,
					'',
					@system_ref_component,
					@system_lib_ref_component,
					@local_ref_component,
					@local_lib_ref_component,
					@subproj_ref_component,
					@target_ref_component
				)
			end

			it 'processes any present references' do
				project = Xcodeproj::Project.new('abc.xcodeproj')
				target = project.new_target(:application, 'ABC', :ios)
				target.frameworks_build_phase.clear
				target.add_system_framework(['UIKit.framework'])
				target.add_system_library(['z'])
				framework = project.new_file File.join(File.dirname(__FILE__), '../support/processor/A.framework')
				library = project.new_file File.join(File.dirname(__FILE__), '../support/processor/A.a')
				target.frameworks_build_phase.add_file_reference framework
				target.frameworks_build_phase.add_file_reference library

				references = nil
				expect { references = @refs_component.process(target) }.to_not raise_error
				expect(references).to be_truthy
				expect(references.count).to eq(4)
			end
		end
	end
end