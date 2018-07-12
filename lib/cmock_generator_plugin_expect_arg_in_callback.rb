class CMockGeneratorPluginExpectArgInCallback
  attr_reader :priority
  attr_accessor :utils

  def initialize(config, utils)
    @utils        = utils
    @priority     = 1
  end
  
  def callback_typedef(function, arg)
	"CMOCK_#{function[:name]}_#{arg[:name]}_CALLBACK"
  end

  def instance_typedefs(function)
    lines = ""
    function[:args].each do |arg|
      if (@utils.ptr_or_str?(arg[:type]))
        lines << "  #{callback_typedef(function, arg)} ExpectArgInCallback_#{arg[:name]}_CallbackFunctionPointer;\n"
        lines << "  #{arg[:type]} ExpectArgInCallback_#{arg[:name]}_Val;\n"
      end
    end
    lines
  end

  def mock_function_declarations(function)
    lines = ""
    function[:args].each do |arg|
      if (@utils.ptr_or_str?(arg[:type]))
        lines << "typedef void (* #{callback_typedef(function, arg)})(#{arg[:type]} expected_#{arg[:name]}, #{arg[:type]} actual_#{arg[:name]});\n"
        # without expected value
        lines << "#define #{function[:name]}_ExpectArgInCallback_#{arg[:name]}(Callback)"
        lines << " #{function[:name]}_CMockExpectArgInCallback_#{arg[:name]}(__LINE__, Callback, ((void*)0))\n"
        # with expected value
        lines << "#define #{function[:name]}_ExpectArgValueInCallback_#{arg[:name]}(Callback, value)"
        lines << " #{function[:name]}_CMockExpectArgInCallback_#{arg[:name]}(__LINE__, Callback, value)\n"
        lines << "void #{function[:name]}_CMockExpectArgInCallback_#{arg[:name]}(UNITY_LINE_TYPE cmock_line, #{callback_typedef(function, arg)} Callback, #{arg[:type]} expected_#{arg[:name]});\n"
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
      if (@utils.ptr_or_str?(arg[:type]))
        lines << "void #{func_name}_CMockExpectArgInCallback_#{arg_name}(UNITY_LINE_TYPE cmock_line, #{callback_typedef(function, arg)} Callback, #{arg[:type]} expected_#{arg[:name]})\n"
        lines << "{\n"
        lines << "  CMOCK_#{func_name}_CALL_INSTANCE* cmock_call_instance = " +
          "(CMOCK_#{func_name}_CALL_INSTANCE*)CMock_Guts_GetAddressFor(CMock_Guts_MemEndOfChain(Mock.#{func_name}_CallInstance));\n"
        lines << "  UNITY_TEST_ASSERT_NOT_NULL(cmock_call_instance, cmock_line, \"#{arg_name} ExpectArgInCallback called before Expect on '#{func_name}'.\");\n"
        lines << "  UNITY_TEST_ASSERT_NOT_NULL(Callback, cmock_line, \"#{arg_name} ExpectArgInCallback #{arg[:name]} cannot be null'.\");\n"
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
        lines << "  if (cmock_call_instance->ExpectArgInCallback_#{arg_name}_CallbackFunctionPointer != NULL)\n"
        lines << "  {\n"
        lines << "    cmock_call_instance->ExpectArgInCallback_#{arg_name}_CallbackFunctionPointer(cmock_call_instance->ExpectArgInCallback_#{arg_name}_Val, #{arg[:name]});\n"
        lines << "  }\n"
      end
    end
    lines
  end
end
