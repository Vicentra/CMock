class CMockGeneratorPluginExpectArgInCallback
  attr_reader :priority
  attr_accessor :utils

  def initialize(config, utils)
    @utils        = utils
    @priority     = 1
  end

  def instance_typedefs(function)
    lines = ""
    function[:args].each do |arg|
      if (@utils.ptr_or_str?(arg[:type]))
		type_def = "CMOCK_#{function[:name]}_#{arg[:name]}_CALLBACK"
        lines << "int ExpectArgInCallback_#{arg[:name]}_Used;\n"
        lines << "#{type_def} ExpectArgInCallback_#{arg[:name]}_CallbackFunctionPointer;\n"
        lines << "#{arg[:type]} ExpectArgInCallback_#{arg[:name]}_Val;\n"
      end
    end
    lines
  end

  def mock_function_declarations(function)
    lines = ""
    function[:args].each do |arg|
      if (@utils.ptr_or_str?(arg[:type]))
		type_def = "CMOCK_#{function[:name]}_#{arg[:name]}_CALLBACK"
		#style  = (@include_count ? 1 : 0) | (function[:args].empty? ? 0 : 2)
		#styles = [ "void", "int cmock_num_calls", function[:args_string], "#{function[:args_string]}, int cmock_num_calls" ]
		lines << "typedef void (* #{type_def})(#{arg[:type]} expected_#{arg[:name]}, #{arg[:type]} actual_#{arg[:name]});\n"
        # without expected value
        lines << "#define #{function[:name]}_ExpectArgInCallback_#{arg[:name]}(Callback)"
        lines << " #{function[:name]}_CMockExpectArgInCallback_#{arg[:name]}(__LINE__, Callback, ((void*)0))\n"
        # with expected value
        lines << "#define #{function[:name]}_ExpectArgValueInCallback_#{arg[:name]}(Callback, value)"
        lines << " #{function[:name]}_CMockExpectArgInCallback_#{arg[:name]}(__LINE__, Callback, value)\n"
        lines << "void #{function[:name]}_CMockExpectArgInCallback_#{arg[:name]}(UNITY_LINE_TYPE cmock_line, #{type_def} Callback, #{arg[:type]} expected_#{arg[:name]});\n"
        #lines << "#define #{function[:name]}_PassArrayThruPtr_#{arg[:name]}(#{arg[:name]}, cmock_len)"
        #lines << " #{function[:name]}_CMockExpectArgInCallback_#{arg[:name]}(__LINE__, #{arg[:name]}, (int)(cmock_len * (int)sizeof(*#{arg[:name]})))\n"
        #lines << "#define #{function[:name]}_ExpectArgInCallback_#{arg[:name]}(#{arg[:name]}, cmock_size)"
        #lines << " #{function[:name]}_CMockExpectArgInCallback_#{arg[:name]}(__LINE__, #{arg[:name]}, cmock_size)\n"
        #lines << "void #{function[:name]}_CMockExpectArgInCallback_#{arg[:name]}(UNITY_LINE_TYPE cmock_line, #{arg[:type].sub! 'const', ''} #{arg[:name]}, int cmock_size);\n"
      end
    end
    lines
  end

  def mock_interfaces(function)
    lines = []
    func_name = function[:name]
    function[:args].each do |arg|
      arg_name = arg[:name]
      arg_type = arg[:type]
      type_def = "CMOCK_#{function[:name]}_#{arg[:name]}_CALLBACK"
      if (@utils.ptr_or_str?(arg[:type]))
        lines << "void #{func_name}_CMockExpectArgInCallback_#{arg_name}(UNITY_LINE_TYPE cmock_line, #{type_def} Callback, #{arg[:type]} expected_#{arg[:name]})\n"
        lines << "{\n"
        lines << "  CMOCK_#{func_name}_CALL_INSTANCE* cmock_call_instance = " +
          "(CMOCK_#{func_name}_CALL_INSTANCE*)CMock_Guts_GetAddressFor(CMock_Guts_MemEndOfChain(Mock.#{func_name}_CallInstance));\n"
        lines << "  UNITY_TEST_ASSERT_NOT_NULL(cmock_call_instance, cmock_line, \"#{arg_name} ExpectArgInCallback called before Expect on '#{func_name}'.\");\n"
        lines << "  UNITY_TEST_ASSERT_NOT_NULL(Callback, cmock_line, \"#{arg_name} ExpectArgInCallback #{arg[:name]} cannot be null'.\");\n"
        lines << "  cmock_call_instance->ExpectArgInCallback_#{arg_name}_Used = 1;\n"
        lines << "  cmock_call_instance->ExpectArgInCallback_#{arg_name}_CallbackFunctionPointer = Callback;\n"
        lines << "  cmock_call_instance->ExpectArgInCallback_#{arg_name}_Val = expected_#{arg_name};\n"
        lines << "}\n\n"
      end
    end
    lines
  end

  def mock_implementation(function)
    lines = []
    function[:args].each do |arg|
      arg_name = arg[:name]
      arg_type = arg[:type]
      if (@utils.ptr_or_str?(arg[:type]))
        lines << "  if (cmock_call_instance->ExpectArgInCallback_#{arg_name}_Used)\n"
        lines << "  {\n"
        lines << "    cmock_call_instance->ExpectArgInCallback_#{arg_name}_CallbackFunctionPointer(cmock_call_instance->ExpectArgInCallback_#{arg_name}_Val, #{arg[:name]});\n"
        #lines << "      cmock_call_instance->ExpectArgInCallback_#{arg_name}_Size);\n"
        lines << "  }\n"
      end
    end
    lines
  end
end
