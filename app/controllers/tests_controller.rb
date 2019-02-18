# frozen_string_literal: true

class TestsController < ApplicationController
  def import
    test = Test.new.import(params[:file])
    binding.pry
  end
end
