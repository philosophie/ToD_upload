require 'roo'

class Test < ApplicationRecord
  def initialize(args = {})
    super(args)
    @spreadsheet = nil
    @title_rows = []
    @header_row = nil
    @empty_column_indexes = []
    @data_rows = []
    @number_of_sample_columns = 0
    @column_offset = 0
    @row_offset = 0
  end

  def import(file)
    @spreadsheet = Roo::Excelx.new(file.path)
    find_title_rows
    find_header_row
    find_data_rows
    @number_of_sample_columns = filter(
      @data_rows.first.map { |c| c[:value] }
    ).length
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

  def find_header_row
    header_row = @spreadsheet.row(@title_rows.length + 1)
    header_row.each_with_index do |content, index|
      @empty_column_indexes << index if content.nil? || content.strip == ''
    end
    @header_row = remove_empty_columns(header_row).map { |c| { value: c } }
    @column_offset = header_row.length - @header_row.length
  end

  def find_data_rows
    rows = @spreadsheet.each_row_streaming.map { |r| r }
    (@title_rows.length + 2..@spreadsheet.last_row).each do |i|
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
    number_of_columns = @header_row.length
    columns_map = {}
    i = 0
    number_of_columns.times do
      column_letter = index_hash[i + @column_offset]
      columns_map[column_letter] = i
      i += 1
    end
    columns_map
  end

  def test_map
    {
      titles: @title_rows,
      header: @header_row,
      data: @data_rows,
      number_of_sample_columns: @number_of_sample_columns,
      columns_map: columns_map,
      row_offset: @row_offset
    }
  end
end
