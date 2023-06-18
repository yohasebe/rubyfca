# frozen_string_literal: true

require "minitest/autorun"

class TestRubyFCA < Minitest::Test
  BIN = File.expand_path("../bin", __dir__)
  TEST_INPUT = File.expand_path("../test/test_input", __dir__)
  TEST_EXPECTED = File.expand_path("../test/test_expected", __dir__)
  TEST_OUTPUT = File.expand_path("../test/test_output", __dir__)

  def test_csv_to_svg
    input_file = "#{TEST_INPUT}/test_data.csv"
    output_file = "#{TEST_OUTPUT}/test_result_01.svg"
    expected_output = File.read("#{TEST_EXPECTED}/test_result_01.svg")

    File.delete(output_file) if File.exist?(output_file)

    `#{BIN}/rubyfca #{input_file} #{output_file} --coloring 1 --full --nodesep 0.8 --ranksep 0.3 --straight`

    assert_equal expected_output, File.read(output_file) if File.exist?(output_file)
  end

  def test_cxt_to_svg
    input_file = "#{TEST_INPUT}/test_data.cxt"
    output_file = "#{TEST_OUTPUT}/test_result_02.svg"
    expected_output = File.read("#{TEST_EXPECTED}/test_result_02.svg")

    File.delete(output_file) if File.exist?(output_file)

    `#{BIN}/rubyfca #{input_file} #{output_file} --coloring 2 --nodesep 0.5 --ranksep 0.3`

    assert_equal expected_output, File.read(output_file) if File.exist?(output_file)
  end

  def test_xlsx_to_svg
    input_file = "#{TEST_INPUT}/test_data_numbers.xlsx"
    output_file = "#{TEST_OUTPUT}/test_result_03.svg"
    expected_output = File.read("#{TEST_EXPECTED}/test_result_03.svg")

    File.delete(output_file) if File.exist?(output_file)

    `#{BIN}/rubyfca #{input_file} #{output_file} --circle --legend --coloring 1 --full --nodesep 0.8 --ranksep 0.3 --straight`

    assert_equal expected_output, File.read(output_file) if File.exist?(output_file)
  end

  def test_numbers
    input_file = "#{TEST_INPUT}/test_data_numbers.xlsx"
    output_file = "#{TEST_OUTPUT}/test_result_04.svg"
    expected_output = File.read("#{TEST_EXPECTED}/test_result_04.svg")

    File.delete(output_file) if File.exist?(output_file)

    `#{BIN}/rubyfca #{input_file} #{output_file} --coloring 1 --full --nodesep 0.8 --ranksep 0.3 --straight`

    assert_equal expected_output, File.read(output_file) if File.exist?(output_file)
  end
end
