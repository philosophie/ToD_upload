# frozen_string_literal: true

class TestsController < ApplicationController
  def import
    test = Test.new.import(params[:file])
    @test_props = {
      pageTitle: test[:titles][0][0],
      data: test[:headers] + test[:data],
      numberOfSampleColumns: test[:number_of_sample_columns],
      columnsMap: test[:columns_map],
      rowOffset: test[:row_offset]
    }
  end
end
