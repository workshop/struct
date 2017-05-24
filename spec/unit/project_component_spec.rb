require_relative '../spec_helper'

RSpec.describe StructCore::Processor::ProjectComponent do
	describe 'process' do
		describe 'when provided a structure type' do
			before(:each) do
				@configs_stub = instance_double('StructCore::Processor::ConfigurationsComponent')
				@targets_stub = instance_double('StructCore::Processor::TargetsComponent')
				@variants_stub = instance_double('StructCore::Processor::VariantsComponent')
				@schemes_stub = instance_double('StructCore::Processor::SchemesComponent')
				@xplat_stub = instance_double('StructCore::Processor::TargetCrossPlatformComponent')
				@project_component = StructCore::Processor::ProjectComponent.new(
					nil,
					'',
					@configs_stub,
					@targets_stub,
					@variants_stub,
					@schemes_stub,
					@xplat_stub
				)
			end

			it 'processes to spec structures' do
				ret = {}
				@project_component.structure = :spec

				allow(@project_component).to receive(:process_xc_project).and_return(ret)
				allow(@project_component).to receive(:process_spec_project).and_return(ret)

				expect(@project_component.process(nil, [])).to eq(ret)
			end

			it 'processes to xcodeproj structures' do
				ret = {}
				@project_component.structure = :xcodeproj

				allow(@project_component).to receive(:process_xc_project).and_return(ret)
				allow(@project_component).to receive(:process_spec_project).and_return(ret)

				expect(@project_component.process(nil, [])).to eq(ret)
			end
		end

		describe 'when provided a spec structure' do
			before(:each) do
				@configs_stub = instance_double('StructCore::Processor::ConfigurationsComponent')
				@targets_stub = instance_double('StructCore::Processor::TargetsComponent')
				@variants_stub = instance_double('StructCore::Processor::VariantsComponent')
				@schemes_stub = instance_double('StructCore::Processor::SchemesComponent')
				@xplat_stub = instance_double('StructCore::Processor::TargetCrossPlatformComponent')
				@configs_stub_ret = [1, 2, 3]
				@targets_stub_ret = [2, 3, 4]

				allow(@configs_stub).to receive(:process).and_return(@configs_stub_ret)
				allow(@targets_stub).to receive(:process).and_return(@targets_stub_ret)
				allow(@variants_stub).to receive(:process).and_return([])
				allow(@schemes_stub).to receive(:process).and_return([])
				allow(@xplat_stub).to receive(:process).and_return([])

				@project_component = StructCore::Processor::ProjectComponent.new(
					:spec,
					'',
					@configs_stub,
					@targets_stub,
					@variants_stub,
					@schemes_stub,
					@xplat_stub
				)
			end

			it 'uses the latest spec version if version metadata is not present in the xcode project' do
				project = Xcodeproj::Project.new('abc.xcodeproj')

				spec = nil
				expect { spec = @project_component.process(project, []).first }.to_not raise_error
				expect(spec).to be_truthy
				spec = spec.dsl
				expect(spec).to be_truthy

				expect(spec.version).to eq(StructCore::LATEST_SPEC_VERSION)
			end

			it 'uses the provided spec version when version metadata is present in the xcode project' do
				project = Xcodeproj::Project.new('abc.xcodeproj')
				project.root_object.attributes = { "Struct.Version" => "1.2.1" }

				spec = nil
				expect { spec = @project_component.process(project, []).first }.to_not raise_error
				expect(spec).to be_truthy
				spec = spec.dsl
				expect(spec).to be_truthy

				expect(spec.version).to eq(StructCore::SPEC_VERSION_121)
			end

			it 'uses the latest spec version when invalid version metadata is present in the xcode project' do
				project = Xcodeproj::Project.new('abc.xcodeproj')
				project.root_object.attributes = { "Struct.Version" => "12312312312WFWEFEWFWE......" }

				spec = nil
				expect { spec = @project_component.process(project, []).first }.to_not raise_error
				expect(spec).to be_truthy
				spec = spec.dsl
				expect(spec).to be_truthy

				expect(spec.version).to eq(StructCore::LATEST_SPEC_VERSION)
			end

			it 'initialises a spec file with targets and configurations' do
				project = Xcodeproj::Project.new('abc.xcodeproj')

				spec = nil
				expect { spec = @project_component.process(project, []).first }.to_not raise_error
				expect(spec).to be_truthy
				spec = spec.dsl

				expect(spec).to be_truthy
				expect(spec.configurations).to eq(@configs_stub_ret)
				expect(spec.targets).to eq(@targets_stub_ret)
			end
		end

		describe 'when provided an xcodeproj structure' do
			before(:each) do
				@configs_stub = instance_double('StructCore::Processor::ConfigurationsComponent')
				@targets_stub = instance_double('StructCore::Processor::TargetsComponent')
				@variants_stub = instance_double('StructCore::Processor::VariantsComponent')
				@schemes_stub = instance_double('StructCore::Processor::SchemesComponent')
				@xplat_stub = instance_double('StructCore::Processor::TargetCrossPlatformComponent')

				allow(@configs_stub).to receive(:process).and_return([])
				allow(@targets_stub).to receive(:process).and_return([])
				allow(@variants_stub).to receive(:process).and_return([])
				allow(@schemes_stub).to receive(:process).and_return([])
				allow(@xplat_stub).to receive(:process).and_return([])
				allow(StructCore::PodAssistant).to receive(:apply_pod_configuration)

				@project_component = StructCore::Processor::ProjectComponent.new(
					:xcodeproj,
					'',
					@configs_stub,
					@targets_stub,
					@variants_stub,
					@schemes_stub,
					@xplat_stub
				)
			end

			it 'uses the specified spec version' do
				project = StructCore::Specfile.new(StructCore::LATEST_SPEC_VERSION, [], [], [], '')
				dsl = nil
				expect { dsl = @project_component.process(project, []).first }.to_not raise_error
				expect(dsl).to be_truthy
				dsl = dsl.dsl

				expect(dsl).to be_truthy
				expect(dsl.root_object.attributes['Struct.Version']).to eq(StructCore::LATEST_SPEC_VERSION.to_s)
			end

			it 'initialises an xcodeproj with targets and configurations' do
				project = StructCore::Specfile.new(StructCore::LATEST_SPEC_VERSION, [{}], [{}], [], '')
				expect(@configs_stub).to receive(:process)
				expect(@targets_stub).to receive(:process)
				expect { @project_component.process(project, []).first }.to_not raise_error
			end
		end
	end
end