import PropTypes from "prop-types";
import React, { Component } from "react";
import ReactDataSheet from "react-datasheet";

export default class Test extends Component {
  constructor(props) {
    super(props);
    this.state = {
      data: this.setData()
    };
  }

  setData = () => {
    const table = [];
    const { data, numberOfSampleColumns } = this.props;
    data.forEach(function(element) {
      if (data.indexOf(element) === 0) {
        const firstRow = [];
        element.forEach(function(cell) {
          if (
            element.indexOf(cell) >= 0 &&
            element.indexOf(cell) < numberOfSampleColumns
          ) {
            firstRow.push(
              Object.assign(cell, { className: "sample-data-column-header" })
            );
          } else {
            firstRow.push(
              Object.assign(cell, { className: "test-data-column-header" })
            );
          }
        });
        table.push(firstRow);
      } else {
        table.push(element);
      }
    });
    return table;
  };

  onCellsChanged = changes => {
    const that = this;
    debugger;
    const data = this.state.data.map(row => [...row]);
    changes.forEach(({ cell, row, col, value }) => {
      data[row][col] = { ...data[row][col], value };
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
