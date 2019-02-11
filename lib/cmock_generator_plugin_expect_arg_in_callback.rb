class CMockGeneratorPluginExpectArgInCallback
  attr_reader :priority
  attr_accessor :utils

  def initialize(config, utils)
    @utils        = utils
    @priority     = 1
  end
  
  def callback_arg_typedef(function, arg)
	"CMOCK_#{function[:name]}_ExpectArg_#{arg[:name]}_CALLBACK"   
  end
  
  def callback_arg_value_typedef(function, arg)
    "CMOCK_#{function[:name]}_ExpectArgValue_#{arg[:name]}_CALLBACK"
  end

  def instance_typedefs(function)
    lines = ""
    if function[:args].length == 0
        return lines
    end
    lines << "#ifndef CMOCK_LEAN\n"
    function[:args].each do |arg|
      lines << "  #{callback_arg_typedef(function, arg)} ExpectArgInCallback_#{arg[:name]}_CallbackFunctionPointer;\n"
      lines << "  #{callback_arg_value_typedef(function, arg)} ExpectArgValueInCallback_#{arg[:name]}_CallbackFunctionPointer;\n"
      lines << "  #{get_type(arg)} ExpectArgInCallback_#{arg[:name]}_Val#{get_array_type(arg)};\n"
    end
    lines << "#endif\n"
    lines
  end

  def mock_function_declarations(function)
    lines = ""
    if function[:args].length == 0
        return lines
    end
    lines << "#ifndef CMOCK_LEAN\n"
    function[:args].each do |arg|
      # without expected value
      lines << "typedef void (* #{callback_arg_typedef(function, arg)})(#{get_type(arg)} actual_#{arg[:name]}#{get_array_type(arg)});\n"
      lines << "#define #{function[:name]}_ExpectArgInCallback_#{arg[:name]}(Callback)"
      lines << " #{function[:name]}_CMockExpectArgInCallback_#{arg[:name]}(__LINE__, Callback)\n"
      lines << "void #{function[:name]}_CMockExpectArgInCallback_#{arg[:name]}(UNITY_LINE_TYPE cmock_line, #{callback_arg_typedef(function, arg)} Callback);\n"
      # with expected value
      lines << "typedef void (* #{callback_arg_value_typedef(function, arg)})(#{get_type(arg)} expected_#{arg[:name]}#{get_array_type(arg)}, #{get_type(arg)} actual_#{arg[:name]}#{get_array_type(arg)});\n"
      lines << "#define #{function[:name]}_ExpectArgValueInCallback_#{arg[:name]}(Callback, value)"
      lines << " #{function[:name]}_CMockExpectArgValueInCallback_#{arg[:name]}(__LINE__, Callback, value)\n"
      lines << "void #{function[:name]}_CMockExpectArgValueInCallback_#{arg[:name]}(UNITY_LINE_TYPE cmock_line, #{callback_arg_value_typedef(function, arg)} Callback, #{get_type(arg)} expected_#{arg[:name]}#{get_array_type(arg)});\n"
    end
    lines << "#endif\n"
    lines
  end

  def mock_interfaces(function)
    lines = []
    if function[:args].length == 0
        return lines
    end
    func_name = function[:name]
    lines << "#ifndef CMOCK_LEAN\n"
    function[:args].each do |arg|
      arg_name = arg[:name]
      arg_type = arg[:type]
      lines << "void #{func_name}_CMockExpectArgValueInCallback_#{arg_name}(UNITY_LINE_TYPE cmock_line, #{callback_arg_value_typedef(function, arg)} Callback, #{get_type(arg)} expected_#{arg[:name]}#{get_array_type(arg)})\n"
      lines << "{\n"
      lines << "  CMOCK_#{func_name}_CALL_INSTANCE* cmock_call_instance = " +
        "(CMOCK_#{func_name}_CALL_INSTANCE*)CMock_Guts_GetAddressFor(CMock_Guts_MemEndOfChain(Mock.#{func_name}_CallInstance));\n"
      lines << "  UNITY_TEST_ASSERT_NOT_NULL(cmock_call_instance, cmock_line, \"#{arg_name} ExpectArgInCallback called before Expect on '#{func_name}'.\");\n"
      lines << "  UNITY_TEST_ASSERT_NOT_NULL(Callback, cmock_line, \"#{arg_name} ExpectArgInCallback #{arg[:name]} cannot be null'.\");\n"
      lines << "  cmock_call_instance->ExpectArgValueInCallback_#{arg_name}_CallbackFunctionPointer = Callback;\n"
      lines << "  cmock_call_instance->ExpectArgInCallback_#{arg_name}_CallbackFunctionPointer = NULL;\n"
      lines << "  cmock_call_instance->ExpectArgInCallback_#{arg_name}_Val = expected_#{arg_name};\n"
      lines << "}\n\n"
      
      lines << "void #{func_name}_CMockExpectArgInCallback_#{arg_name}(UNITY_LINE_TYPE cmock_line, #{callback_arg_typedef(function, arg)} Callback)\n"
      lines << "{\n"
      lines << "  CMOCK_#{func_name}_CALL_INSTANCE* cmock_call_instance = " +
        "(CMOCK_#{func_name}_CALL_INSTANCE*)CMock_Guts_GetAddressFor(CMock_Guts_MemEndOfChain(Mock.#{func_name}_CallInstance));\n"
      lines << "  UNITY_TEST_ASSERT_NOT_NULL(cmock_call_instance, cmock_line, \"#{arg_name} ExpectArgInCallback called before Expect on '#{func_name}'.\");\n"
      lines << "  UNITY_TEST_ASSERT_NOT_NULL(Callback, cmock_line, \"#{arg_name} ExpectArgInCallback #{arg[:name]} cannot be null'.\");\n"
      lines << "  cmock_call_instance->ExpectArgInCallback_#{arg_name}_CallbackFunctionPointer = Callback;\n"
      lines << "  cmock_call_instance->ExpectArgValueInCallback_#{arg_name}_CallbackFunctionPointer = NULL;\n"
      lines << "}\n\n"
    end
    lines << "#endif\n"
    lines
  end

  def mock_implementation(function)
    lines = []
    if function[:args].length == 0
        return lines
    end
    lines << "#ifndef CMOCK_LEAN\n"
    function[:args].each do |arg|
      arg_name = arg[:name]
      arg_type = arg[:type]
      lines << "  if (cmock_call_instance->ExpectArgInCallback_#{arg_name}_CallbackFunctionPointer != NULL)\n"
      lines << "  {\n"
      lines << "    cmock_call_instance->ExpectArgInCallback_#{arg_name}_CallbackFunctionPointer(#{arg[:name]});\n"
      lines << "  }\n"
      lines << "  if (cmock_call_instance->ExpectArgValueInCallback_#{arg_name}_CallbackFunctionPointer != NULL)\n"
      lines << "  {\n"
      lines << "    cmock_call_instance->ExpectArgValueInCallback_#{arg_name}_CallbackFunctionPointer(cmock_call_instance->ExpectArgInCallback_#{arg_name}_Val, #{arg[:name]});\n"
      lines << "  }\n"
    end
    lines << "#endif\n"
    lines
  end

  def get_type(arg)
    if !arg[:arrayType].nil? and arg[:type].include?('*')
        return arg[:type].clone.insert(-2, '(')
    else
        return arg[:type]
    end
  end

  def get_array_type(arg)
    if !arg[:arrayType].nil? and arg[:type].include?('*')
        return ')' + arg[:arrayType]
    else
        return arg[:arrayType]
    end
  end
end
