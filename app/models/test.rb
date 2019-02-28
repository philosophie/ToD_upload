require 'roo'
require 'rubyXL/convenience_methods'

class Test < ApplicationRecord
  def initialize(args = {})
    super(args)
    @spreadsheet = nil
    @title_rows = []
    @header_rows = []
    @empty_column_indexes = []
    @data_rows = []
    @column_offset = 0
    @row_offset = 0
    @number_of_sample_columns = 1
    @header_rows_length = 1
  end

  def import(file)
    @spreadsheet = Roo::Excelx.new(file.path)
    @column_offest = @spreadsheet.first_column
    parsed_for_colors = RubyXL::Parser.parse(file.path)[0]
    find_title_rows
    samples_color = parsed_for_colors[@row_offset][@spreadsheet.first_column].fill_color
    while parsed_for_colors[@row_offset][@number_of_sample_columns + 1].fill_color == samples_color
      @number_of_sample_columns = @number_of_sample_columns + 1
    end
    while parsed_for_colors[@row_offset + @header_rows_length][@spreadsheet.first_column].fill_color == samples_color
      @header_rows_length = @header_rows_length + 1
    end
    find_header_rows
    find_data_rows
    test_map
  end

  def find_title_rows
    (1..@spreadsheet.last_row).each do |i|
      filtered_row = filter(@spreadsheet.row(i))
      break if filtered_row.length > 3

      @title_rows << filtered_row
    end
    @row_offset = @title_rows.length
  end

  def find_header_rows
    header_rows = []
    i = @title_rows.length + 1
    until i > @header_rows_length + @title_rows.length
      header_rows << @spreadsheet.row(i)
      i = i + 1
    end
    i = 0
    until i == header_rows.last.length
      empty_cells_counter = 0
      header_rows.each do |row|
        if row[i] == nil || row[i].strip == ''
          empty_cells_counter = empty_cells_counter + 1
        end
      end
      if empty_cells_counter == header_rows.length
        @empty_column_indexes << i
      end
      empty_cells_counter = 0
      i = i + 1
    end
    @header_rows = header_rows.map { |row| remove_empty_columns(row) }
    @header_rows = @header_rows.map do |row|
      row.map do |cell|
        {
          value: cell,
          className: row.index(cell) < @number_of_sample_columns? "sample-data-column-header" : "test-data-column-header"
        }
      end
    end
    deletion_map = {}
    @header_rows.each_with_index do |row, row_index|
    	row.each_with_index do |cell, cell_index|
    		row_span = 1
    		row_counter = 1
    		if cell[:value]
    			until row_index + row_counter == @header_rows.length
    				if @header_rows[row_index + row_counter][cell_index][:value] == nil
    					row_span = row_span + 1
    					row_counter = row_counter + 1
    				else
    					break
    				end
    			end
    			@header_rows[row_index][cell_index][:rowSpan] = row_span
    			(row_index + 1..row_span - 1).each do |i|
            if deletion_map[i]
              deletion_map[i] = deletion_map[i].push(cell_index)
            else
              deletion_map[i] = [cell_index]
            end
    			end
    		end
    	end
    end
    @header_rows_copy = @header_rows.map {|x| x}
    deletion_map.keys.each do |row_index|
      @header_rows[row_index] = @header_rows[
        row_index
      ].reject.with_index do |_x, cell_index|
        deletion_map[row_index].include?(cell_index)
      end
    end
    @header_rows.each_with_index do |row, row_index|
    	row.each_with_index do |cell, cell_index|
    		column_span = 1
    		column_counter = 1
    		if cell[:value]
    			until cell_index + column_counter == @header_rows[row_index].length
    				if @header_rows[row_index][cell_index + column_counter][:value] == nil
    					column_span = column_span + 1
    					column_counter = column_counter + 1
              unless row_index == 0 || cell_index + column_span + 1 >= @header_rows[row_index].length
                index_check = @header_rows_copy[row_index].index(cell) + column_span
                if @header_rows[row_index - 1][index_check][:rowSpan] &&
                   @header_rows[row_index - 1][index_check][:rowSpan] > 1
                   break
                end
              end
    				else
    					break
    				end
    			end
    			@header_rows[row_index][cell_index][:colSpan] = column_span
    		end
    	end
    end
    @header_rows = @header_rows.map do |row|
      row.select do |content|
        !content[:value].nil? && content[:value].to_s.strip != ''
      end
    end
  end

  def find_data_rows
    rows = @spreadsheet.each_row_streaming.map { |r| r }
    (@header_rows_length + @title_rows.length + 1..@spreadsheet.last_row).each do |i|
      data_row = remove_empty_columns(@spreadsheet.row(i))
      break if data_row.reject(&:nil?).empty?

      data_row = data_row.map do |cell|
        cell_info = rows[i - 1].select { |c| c.value == cell }[0]
        if cell_info.formula
          { isFormula: true, value: cell, formula: cell_info.formula }
        else
          { value: cell }
        end
      end
      @data_rows << data_row
    end
  end

  def filter(row)
    row.select do |content|
      !content.nil? && content.to_s.strip != ''
    end
  end

  def remove_empty_columns(row)
    row.reject.with_index do |_x, i|
      @empty_column_indexes.include?(i)
    end
  end

  def columns_map
    index_hash = Hash.new { |hash, key| hash[key] = hash[key - 1].next }.merge(0 => 'A')
    number_of_columns = @header_rows.last.length
    columns_map = {}
    i = 0
    number_of_columns.times do
      column_letter = index_hash[i + @column_offest]
      columns_map[column_letter] = i
      i += 1
    end
    columns_map
  end

  def test_map
    {
      titles: @title_rows,
      headers: @header_rows,
      data: @data_rows,
      number_of_sample_columns: @number_of_sample_columns,
      columns_map: columns_map,
      row_offset: @row_offset
    }
  end
end
