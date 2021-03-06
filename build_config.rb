MRuby::Build.new do |conf|
  # load specific toolchain settings

  # Gets set by the VS command prompts.
  if ENV['VisualStudioVersion'] || ENV['VSINSTALLDIR']
    toolchain :visualcpp
  else
    toolchain :gcc
  end

  enable_debug

  # Use mrbgems
  # conf.gem 'examples/mrbgems/ruby_extension_example'
  # conf.gem 'examples/mrbgems/c_extension_example' do |g|
  #   g.cc.flags << '-g' # append cflags in this gem
  # end
  # conf.gem 'examples/mrbgems/c_and_ruby_extension_example'
  # conf.gem :github => 'masuidrive/mrbgems-example', :checksum_hash => '76518e8aecd131d047378448ac8055fa29d974a9'
  # conf.gem :git => 'git@github.com:masuidrive/mrbgems-example.git', :branch => 'master', :options => '-v'

  # include the default GEMs
  conf.gembox 'default'

  # C compiler settings
  # conf.cc do |cc|
  #   cc.command = ENV['CC'] || 'gcc'
  #   cc.flags = [ENV['CFLAGS'] || %w()]
  #   cc.include_paths = ["#{root}/include"]
  #   cc.defines = %w(DISABLE_GEMS)
  #   cc.option_include_path = '-I%s'
  #   cc.option_define = '-D%s'
  #   cc.compile_options = "%{flags} -MMD -o %{outfile} -c %{infile}"
  # end

  # mrbc settings
  # conf.mrbc do |mrbc|
  #   mrbc.compile_options = "-g -B%{funcname} -o-" # The -g option is required for line numbers
  # end

  # Linker settings
  # conf.linker do |linker|
  #   linker.command = ENV['LD'] || 'gcc'
  #   linker.flags = [ENV['LDFLAGS'] || []]
  #   linker.flags_before_libraries = []
  #   linker.libraries = %w()
  #   linker.flags_after_libraries = []
  #   linker.library_paths = []
  #   linker.option_library = '-l%s'
  #   linker.option_library_path = '-L%s'
  #   linker.link_options = "%{flags} -o %{outfile} %{objs} %{libs}"
  # end

  # Archiver settings
  # conf.archiver do |archiver|
  #   archiver.command = ENV['AR'] || 'ar'
  #   archiver.archive_options = 'rs %{outfile} %{objs}'
  # end

  # Parser generator settings
  # conf.yacc do |yacc|
  #   yacc.command = ENV['YACC'] || 'bison'
  #   yacc.compile_options = '-o %{outfile} %{infile}'
  # end

  # gperf settings
  # conf.gperf do |gperf|
  #   gperf.command = 'gperf'
  #   gperf.compile_options = '-L ANSI-C -C -p -j1 -i 1 -g -o -t -N mrb_reserved_word -k"1,3,$" %{infile} > %{outfile}'
  # end

  # file extensions
  # conf.exts do |exts|
  #   exts.object = '.o'
  #   exts.executable = '' # '.exe' if Windows
  #   exts.library = '.a'
  # end

  # file separetor
  # conf.file_separator = '/'

  # bintest
  # conf.enable_bintest
end

# Define cross build settings
# MRuby::CrossBuild.new('32bit') do |conf|
#   toolchain :gcc
#
#   conf.cc.flags << "-m32"
#   conf.linker.flags << "-m32"
#
#   conf.build_mrbtest_lib_only
#
#   conf.gem 'examples/mrbgems/c_and_ruby_extension_example'
#
#   conf.test_runner.command = 'env'
#
# end

# Define cross build settings
MRuby::CrossBuild.new('c674x') do |conf|
  toolchain :gcc
  
  # Use standard Kernel#sprintf method
  conf.gem "#{root}/mrbgems/mruby-sprintf"
  
  # Use standard print/puts/p
  conf.gem "#{root}/mrbgems/mruby-print"
  
  # Use standard Time class
  conf.gem "#{root}/mrbgems/mruby-time" do |g|
     g.cc.defines += ['USE_SYSTEM_TIMEGM', 'NO_GETTIMEOFDAY', 'NO_GMTIME_R']
  end
  
  # Use standard Math module
  conf.gem "#{root}/mrbgems/mruby-math"
  
  # Use eval method
  conf.gem "#{root}/mrbgems/mruby-eval"
  
  #conf.gem 'examples/mrbgems/c_and_ruby_extension_example'
  
  ti_root = ["C:/Tools/Embedded/TI", "C:/Program Files/TI"].find{|dir| FileTest::exist?(dir)}
  
  # Automatically select the newest compiler 
  cg_tool_path_candidates = Dir::glob("#{ti_root}/ccsv5/tools/compiler/c6000_*").collect{|dir_name|
    dir_name =~ /_(\d+)\.(\d+)\.(\d+)$/
    [dir_name, $1.to_i, $2.to_i, $3.to_i]
  }.sort{|a, b|
    res = (b[1] <=> a[1])
    if res == 0 then
      res = (b[2] <=> a[2])
      res = (b[3] <=> a[3]) if res == 0
    end
    res    
  }
  cg_tool_path = cg_tool_path_candidates.first[0]
  
  conf.cc{|cc|
    cc.command="#{cg_tool_path}/bin/cl6x.exe"
    cc.flags = [
        '-mv6740',
        '--abi=coffabi',
        '-g',
        #'--cpp_default', # with define '__STDC_LIMIT_MACROS'
        '--interrupt_threshold=1000',
        '--mem_model:data=far',
        #'-k', # keep assembly language
        '--gcc',
        '-U=__GNUC__',
        '-o1',
        '-mf5',
        ]
    cc.include_paths += [
        "#{cg_tool_path}/include",
        "#{ti_root}/dsplib_c674x_3_1_1_1/inc",
        "#{ti_root}/mathlib_c674x_3_0_2_0/inc"]
    cc.defines += [
        '_Bool=int',]
    cc.option_include_path = '--include_path=%s'
    cc.option_define = '-D%s'
    cc.compile_options = "%{flags} --output_file=%{outfile} %{infile}"
  }

  conf.linker{|linker|
    linker.command = "#{cg_tool_path}/bin/lnk6x.exe"
    linker.flags += [
        '-mv6740',
        '--abi=coffabi',
        '-g',
        '--interrupt_threshold=1000',
        '--mem_model:data=far',
        #'-k', # keep assembly language
        '-z',]
    #linker.flags_before_libraries = ...
    linker.libraries = [
        'mathlib.a674',
        'dsplib.a674',
        'libc.a',]
    linker.flags_after_libraries = [
        '--reread_libs', 
        '--warn_sections', 
        '--rom_model',]
    linker.library_paths = [
        "#{cg_tool_path}/lib",
        "#{ti_root}/mathlib_c674x_3_0_2_0/lib",
        "#{ti_root}/dsplib_c674x_3_1_1_1/lib",]
    linker.option_library = '-l%s'
    linker.option_library_path = '-i%s'
    linker.link_options = "%{flags} -o %{outfile} %{objs} %{libs}"
  }
  
  conf.archiver{|archiver|
    archiver.command = "#{cg_tool_path}/bin/ar6x.exe"
    #archiver.archive_options = 'rs %{outfile} %{objs}'
  }

  conf.bins = []
end
