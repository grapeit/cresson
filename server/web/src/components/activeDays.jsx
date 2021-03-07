import React, { Component } from "react";

class ActiveDays extends Component {
  state = {
    days: [],
  };

  render() {
    if (this.state.days.length === 0) {
      return <button onClick={this.loadActiveDays}>Load active days</button>;
    }
    return (
      <React.Fragment>
        {this.state.days.map((day) => (
          <button>{day.date + " (" + day.records + ")"}</button>
        ))}
      </React.Fragment>
    );
  }

  loadActiveDays = () => {
    fetch("https://cresson-api.the-grape.com/active-days")
      .then((data) => data.json())
      .then((data) => this.setState({ days: data.days }));
  };
}

export default ActiveDays;
