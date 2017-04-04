require_relative '../spec_helper'

RSpec.describe StructCore::Processor::TargetResourcesComponent do
	describe 'process' do
		describe 'when provided a spec structure' do
			before(:each) do
				@res_stub = instance_double('StructCore::Processor::TargetResourceComponent')
				allow(@res_stub).to receive(:process).and_return(123)
				@resources_component = StructCore::Processor::TargetResourcesComponent.new(
					:spec,
					'',
					@res_stub
				)
			end

			it 'processes any resource files added to the target' do
				project = Xcodeproj::Project.new('abc.xcodeproj')
				target = project.new_target(:application, 'ABC', :ios, nil, nil, :swift)
				res_file = File.join(File.dirname(__FILE__), '../support/processor/res_multiple/Base.lproj/A.storyboard')
				ref = project.new_file res_file
				target.add_resources [ref]

				spec = nil
				expect { spec = @resources_component.process(target) }.to_not raise_error
				expect(spec).to be_truthy
				expect(spec.count).to be(1)
				expect(spec[0]).to be(123)
			end
		end

		describe 'when provided an xcodeproj structure' do
			before(:each) do
				@res_stub = instance_double('StructCore::Processor::TargetResourceComponent')
				allow(@res_stub).to receive(:process)
				@resources_component = StructCore::Processor::TargetResourcesComponent.new(
					:xcodeproj,
					'',
					@res_stub
				)
			end

			it 'processes any resource files in a res_dir folder' do
				target = StructCore::Specfile::Target.new(
					'ABC',
					'ios',
					[],
					[],
					[],
					[],
					[
						File.join(File.dirname(__FILE__), '../support/processor/res_multiple')
					],
					[]
				)

				project = Xcodeproj::Project.new('abc.xcodeproj')
				target_dsl = project.new_target(:application, 'ABC', :ios, nil, nil, :swift)

				expect { @resources_component.process(target, target_dsl, project) }.to_not raise_error
				expect(project.groups.count).to be(3)

				lang_group = project.groups.find { |g| g.name == '$lang:ABC' }
				expect(lang_group).to be_truthy
				expect(lang_group.children.count).to be(2)

			end
		end
	end
end