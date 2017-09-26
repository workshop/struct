spec('3.0.0') do
	configuration('my-configuration') do
		override 'OVERRIDE', '1'
		type 'debug'
  end
  script 'a', 'support_files/script.sh'
	target('my-target') do
		type :application
		source_dir 'support_files/abc'
		configuration do end
		script 'support_files/script.sh' do
			input 'ABC'
			output 'DEF'
			shell 'HIJ'
		end
	end
end