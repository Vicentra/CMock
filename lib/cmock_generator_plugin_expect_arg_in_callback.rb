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
    function[:args].each do |arg|
      lines << "  #{callback_arg_typedef(function, arg)} ExpectArgInCallback_#{arg[:name]}_CallbackFunctionPointer;\n"
      lines << "  #{callback_arg_value_typedef(function, arg)} ExpectArgValueInCallback_#{arg[:name]}_CallbackFunctionPointer;\n"
      lines << "  #{arg[:type]} ExpectArgInCallback_#{arg[:name]}_Val;\n"
    end
    lines
  end

  def mock_function_declarations(function)
    lines = ""
    function[:args].each do |arg|
      # without expected value
      lines << "typedef void (* #{callback_arg_typedef(function, arg)})(#{arg[:type]} actual_#{arg[:name]});\n"
      lines << "#define #{function[:name]}_ExpectArgInCallback_#{arg[:name]}(Callback)"
      lines << " #{function[:name]}_CMockExpectArgInCallback_#{arg[:name]}(__LINE__, Callback)\n"
      lines << "void #{function[:name]}_CMockExpectArgInCallback_#{arg[:name]}(UNITY_LINE_TYPE cmock_line, #{callback_arg_typedef(function, arg)} Callback);\n"
      # with expected value
      lines << "typedef void (* #{callback_arg_value_typedef(function, arg)})(#{arg[:type]} expected_#{arg[:name]}, #{arg[:type]} actual_#{arg[:name]});\n"
      lines << "#define #{function[:name]}_ExpectArgValueInCallback_#{arg[:name]}(Callback, value)"
      lines << " #{function[:name]}_CMockExpectArgValueInCallback_#{arg[:name]}(__LINE__, Callback, value)\n"
      lines << "void #{function[:name]}_CMockExpectArgValueInCallback_#{arg[:name]}(UNITY_LINE_TYPE cmock_line, #{callback_arg_value_typedef(function, arg)} Callback, #{arg[:type]} expected_#{arg[:name]});\n"
    end
    lines
  end

  def mock_interfaces(function)
    lines = []
    func_name = function[:name]
    function[:args].each do |arg|
      arg_name = arg[:name]
      arg_type = arg[:type]
      lines << "void #{func_name}_CMockExpectArgValueInCallback_#{arg_name}(UNITY_LINE_TYPE cmock_line, #{callback_arg_value_typedef(function, arg)} Callback, #{arg[:type]} expected_#{arg[:name]})\n"
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
    lines
  end

  def mock_implementation(function)
    lines = []
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
    lines
  end
end
