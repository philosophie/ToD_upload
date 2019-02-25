import PropTypes from "prop-types";
import React, { Component } from "react";
import ReactDataSheet from "react-datasheet";

export default class Test extends Component {
  constructor(props) {
    super(props);
    // debugger;
    this.state = {
      data: [],
      formulaCells: []
    };
  }

  componentDidMount = () => {
    this.setData();
  };

  processFormulas = () => {
    const { processFormula } = this;
    this.setState({
      data: this.state.data.map(row =>
        row.map(cell =>
          cell["isFormula"]
            ? Object.assign(cell, { value: processFormula(cell["formula"]) })
            : cell
        )
      )
    });
  };

  processFormula = (formula, data) => {
    const { columnsMap } = this.props;
    const rowOffset = this.props.rowOffset + 1;
    const formulaType = formula.split("(")[0];
    const range = formula
      .split("(")[1]
      .split(":")
      .map(x => x.replace(/\W/g, ""));
    const startingColumn = range[0].replace(/[0-9]/g, "");
    const endingColumn = range[1].replace(/[0-9]/g, "");
    if (startingColumn == endingColumn && formulaType == "SUM") {
      const startingRow = parseInt(range[0].replace(/^\D+/g, "")) - rowOffset;
      const endingRow = parseInt(range[1].replace(/^\D+/g, "")) - rowOffset;
      const rows_to_sum = data.slice(startingRow, endingRow + 1);
      const cells_to_sum = rows_to_sum.map(r => r[columnsMap[startingColumn]]);
      return parseFloat(
        cells_to_sum
          .filter(c => c["value"] !== null && parseFloat(c["value"]))
          .map(c => parseFloat(c["value"]))
          .reduce(function(a, b) {
            return a + b;
          }, 0)
      );
    }
    return formula;
  };

  setData = () => {
    const table = [];
    const { data } = this.props;
    const { processFormula } = this;
    const formulaCells = [];
    data.forEach(function(row, row_index) {
      row.forEach(function(cell, cell_index) {
        if (cell["isFormula"]) {
          formulaCells.push(new Array(row_index, cell_index));
        }
      });
    });
    this.setState({
      data,
      formulaCells
    });
  };

  onCellsChanged = changes => {
    const { processFormula } = this;
    const data = this.state.data.map(row => [...row]);
    changes.forEach(({ cell, row, col, value }) => {
      data[row][col] = { ...data[row][col], value };
    });
    this.state.formulaCells.forEach(function(coordinates) {
      data[coordinates[0]][coordinates[1]]["value"] = processFormula(
        data[coordinates[0]][coordinates[1]]["formula"],
        data
      );
    });
    this.setState({ data });
  };

  render() {
    return (
      <div>
        <h1>{this.props.pageTitle}</h1>
        <ReactDataSheet
          data={this.state.data}
          valueRenderer={cell => cell.value}
          onCellsChanged={this.onCellsChanged}
        />
      </div>
    );
  }
}
