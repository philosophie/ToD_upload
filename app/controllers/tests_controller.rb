# frozen_string_literal: true

class TestsController < ApplicationController
  def import
    test = Test.new.import(params[:file])
    fail
    @test_props = {
      pageTitle: test[:titles][0][0],
      data: [test[:header]] + test[:data],
      numberOfSampleColumns: test[:number_of_sample_columns],
      columnsMap: test[:columns_map],
      rowOffset: test[:row_offset]
    }
  end
end
