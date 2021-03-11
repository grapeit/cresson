import React, { Component } from "react";

class RideChart extends Component {
  render() {
    if (this.props.day == null) {
      return <h2>khuy</h2>;
    }
    return (
      <h2>
        {this.props.day.records} events on {this.props.day.date}
      </h2>
    );
  }
}

export default RideChart;
